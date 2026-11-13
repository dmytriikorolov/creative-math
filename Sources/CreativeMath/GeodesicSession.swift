import Foundation
import Observation
import WorkspaceCore

@MainActor @Observable
final class GeodesicSession: SurfaceMotionSession {
    let surface = SurfaceSession(preset: .torus)
    var configuration = TorusGeodesicConfiguration() { didSet { rebuild() } }
    var playbackRate = 2.0 { didSet { playback.playbackRate = playbackRate; revision &+= 1 } }
    var appearance = GeodesicAppearance() { didSet { revision &+= 1 } }
    var trailLength = 8192 { didSet { rebuild() } }
    var fade = TrailFade(delay: 12,duration: 18) { didSet { revision &+= 1 } }
    var isPaused = false {
        didSet { playback.isPaused = isPaused; revision &+= 1 }
    }
    private(set) var revision: UInt64 = 0
    private(set) var restartID: UInt64 = 0
    var diagnostics = "RK4 · Δt = 1/240 s"
    private var tracking = ParticleCameraTracking()
    // Read only by the coordinate-label child view, not the workspace/inspector.
    private(set) var annotationCamera = SurfacePreset.torus.camera
    var isFollowing: Bool {
        get { tracking.isFollowing }
        set {
            tracking.setFollowing(newValue,camera: &surface.camera,particle: playback.solver.position)
            revision &+= 1
        }
    }
    @ObservationIgnored var playback: GeodesicPlayback
    init(preview: Bool = false) {
        // Defaults are validated by the same throwing path used for every edit.
        do {
            var value = try GeodesicPlayback(configuration: TorusGeodesicConfiguration())
            if preview { for _ in 0..<480 { try value.advance(elapsed: 1.0/60) }; value.isPaused = true }
            value.playbackRate = 2
            playback = value; isPaused = preview
        } catch { preconditionFailure("Invalid built-in torus geodesic defaults: \(error)") }
    }
    var renderedTrail: GeodesicTrail { playback.trail }
    func advance(elapsed: Double) throws { try playback.advance(elapsed: elapsed) }
    func restart() { playback.restart(); surface.failure = nil; restartID &+= 1; revision &+= 1; updateDiagnostics() }
    func step() {
        do { try playback.singleStep(); revision &+= 1; updateDiagnostics() }
        catch { surface.failure = error.localizedDescription; isPaused = true }
    }
    func restoreDefaults() {
        tracking = ParticleCameraTracking()
        surface.select(.torus); playbackRate = 2; appearance = GeodesicAppearance(); fade = TrailFade(delay: 12,duration: 18)
        trailLength = 8192; configuration = TorusGeodesicConfiguration()
    }
    func cameraForFrame() -> OrbitCamera {
        tracking.resolved(camera: surface.camera,particle: playback.solver.position)
    }
    func recordAnnotationCamera(_ camera: OrbitCamera) {
        if surface.grid.visible, annotationCamera != camera { annotationCamera = camera }
    }
    func resetCamera() {
        tracking.reset(camera: &surface.camera,preset: SurfacePreset.torus.camera)
        revision &+= 1
    }
    func updateDiagnostics() {
        diagnostics = String(format: "t = %.2f s · Δspeed = %+.3e\nRK4 · Δt = 1/240 s · dropped %.3f s",Double(playback.solver.steps)*TorusGeodesicConfiguration.timestep,
                             playback.solver.relativeSpeedDrift,playback.clock.discardedTime)
    }
    private func rebuild() {
        do {
            var value = try GeodesicPlayback(configuration: configuration,trailLength: trailLength)
            value.isPaused = isPaused; value.playbackRate = playbackRate; playback = value
            surface.parameters.majorRadius = configuration.torus.majorRadius
            surface.parameters.tubeRadius = configuration.torus.minorRadius
            surface.failure = nil; restartID &+= 1; revision &+= 1
            updateDiagnostics()
        } catch { surface.failure = error.localizedDescription; isPaused = true }
    }
}
