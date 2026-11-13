import AppKit
import Foundation
import Observation
import WorkspaceCore

@MainActor @Observable
final class WormholeSession: SurfaceMotionSession {
    let surface = SurfaceSession(preset: .wormhole)
    var beam = WormholeBeam() { didSet { rebuild() } }
    var presentation: WormholeSurfaceAppearance = {
        var value = WormholeSurfaceAppearance(); value.mode = .wireframe; value.opacity = 1; return value
    }() { didSet { revision &+= 1 } }
    var showOtherRegion = true { didSet { revision &+= 1 } }
    var appearance = GeodesicAppearance() { didSet { revision &+= 1 } }
    var fade = TrailFade(delay: 30,duration: 30) { didSet { revision &+= 1 } }
    var trailLength = 8192 { didSet { rebuild() } }
    var playbackRate = 2.0 { didSet { revision &+= 1 } }
    var launches: WormholeLaunchSettings = {
        var value = WormholeLaunchSettings(); value.continuous = true; return value
    }() { didSet { rebuild() } }
    var isPaused = false { didSet { revision &+= 1 } }
    private(set) var selectedBall = 0
    private(set) var revision: UInt64 = 0
    private(set) var restartID: UInt64 = 0
    private(set) var diagnostics = "Same speed and heading; different starting positions."
    @ObservationIgnored private var tracking = RelaunchCameraTracking()
    private(set) var followingEnabled = false
    private(set) var followStatus = ""
    private(set) var annotationCamera = WormholeBeam().geometry.camera
    @ObservationIgnored var roundedComparison: RoundedWormholeComparison?
    @ObservationIgnored var comparison: WormholeComparison
    var roundedReturnEdge: Bool {
        get { beam.geometry.funnel?.roundedReturnEdge ?? false }
        set { beam.geometry.funnel?.roundedReturnEdge = newValue }
    }
    init(preview: Bool = false) {
        do {
            var settings = WormholeLaunchSettings(); settings.continuous = true
            var value = try WormholeComparison(beam: WormholeBeam(),launches: settings)
            if preview {
                for _ in 0..<360 { try value.advance(elapsed: 1.0/60,paused: false,rate: 4) }
                try value.advance(elapsed: 0,paused: true,rate: 4)
            }
            comparison = value; isPaused = preview; surface.camera = WormholeBeam().geometry.camera
            surface.camera.target.y = -(WormholeBeam().geometry.funnel?.depth ?? 7)
        } catch { preconditionFailure("Invalid built-in comparison: \(error)") }
    }
    var maximumRenderTracks: Int { 17 }
    var renderedTrail: GeodesicTrail { roundedComparison?.tracks[selectedBall].trail ?? comparison.tracks[selectedBall].trail }
    var displayedParticle: SIMD3<Double>? { selectedPosition }
    private var selectedPosition: SIMD3<Double> { roundedComparison?.tracks[selectedBall].presentationPosition ?? comparison.tracks[selectedBall].presentationPosition }
    var renderBatch: [GeodesicRenderTrack]? {
        if let roundedComparison {
            return roundedComparison.tracks.indices.filter { roundedComparison.isVisible($0) }.map { index in
                let track = roundedComparison.tracks[index], p = track.presentationPosition
                let color: SIMD4<Float> = index == selectedBall ? SIMD4(1,0.82,0.45,1) : SIMD4(0.62,0.72,0.80,1)
                return GeodesicRenderTrack(trail: track.trail,particle: p,color: color,appearance: appearance,ballNormal: track.solver.surface.normal(at: p))
            }
        }
        return comparison.tracks.indices.filter { comparison.isVisible($0) }.map { index in
            let track = comparison.tracks[index]
            var style = appearance
            let color: SIMD4<Float>
            if index == selectedBall { color = SIMD4(1,0.82,0.45,1); style.trailWidthPoints = min(3,style.trailWidthPoints*1.35) }
            else if track.solver.state.x < 0 { color = SIMD4(0.35,0.72,0.58,0.9) }
            else if track.solver.state.z > 0 { color = SIMD4(0.88,0.55,0.20,0.9) }
            else { color = SIMD4(0.62,0.72,0.80,0.85) }
            // Analytic normal enables sphere shading; ball and trail share one center.
            let geometry = beam.geometry, particle = track.presentationPosition
            let l = geometry.throatRadius*sinh((particle.y+(geometry.funnel?.depth ?? 0))/geometry.axialScale)
            let normal = -geometry.normal(l: l,phi: atan2(particle.z,particle.x))
            return GeodesicRenderTrack(trail: track.trail,particle: particle,color: color,appearance: style,ballNormal: normal)
        }
    }
    var depthTolerance: Float { 0.04 }
    var ellisGeometry: EllisWormhole? {
        var geometry = beam.geometry; geometry.funnel?.showsOtherRegion = showOtherRegion || roundedReturnEdge; return geometry
    }
    var ellisAppearance: WormholeSurfaceAppearance? { presentation }
    var canAdvance: Bool { beam.isValid && surface.failure == nil }
    var isFollowing: Bool {
        get { followingEnabled }
        set {
            tracking.setFollowing(newValue,camera: &surface.camera,particle: selectedIsVisible ? selectedPosition : nil)
            followingEnabled = tracking.isFollowing
            updateFollowStatus()
            revision &+= 1
        }
    }
    var selectedIsVisible: Bool { roundedComparison?.isVisible(selectedBall) ?? comparison.isVisible(selectedBall) }
    var summary: String {
        if launches.continuous {
            let visible = beam.starts.indices.filter { roundedComparison?.isVisible($0) ?? comparison.isVisible($0) }.count
            return "Continuous launches · \(visible) active · seed \(launches.seed)"
        }
        if roundedReturnEdge { return "Rounded +X return edge · other three edges remain open" }
        let through = comparison.tracks.filter { $0.solver.state.x < 0 }.count
        let outward = comparison.tracks.filter { $0.solver.state.x >= 0 && $0.solver.state.z > 0 }.count
        return "\(through) through throat · \(outward) outward · balls disappear beyond the grid"
    }
    private var selectedHasDisappeared: Bool {
        roundedComparison?.tracks[selectedBall].hasDisappeared ?? comparison.tracks[selectedBall].hasDisappeared
    }
    var selectedOutcome: String {
        if launches.continuous && !selectedIsVisible { return "Waiting for launch" }
        if selectedHasDisappeared { return "Left surface · hidden until restart" }
        if let roundedComparison {
            return roundedComparison.tracks[selectedBall].solver.position.y >= -(beam.geometry.funnel?.depth ?? 7) ? "Upper sheet" : "Lower sheet"
        }
        return comparison.outcome(selectedBall)
    }
    func selectBall(_ index: Int) {
        guard (0..<(roundedComparison?.tracks.count ?? comparison.tracks.count)).contains(index) else { return }
        selectedBall = index
        tracking.select(particle: selectedIsVisible ? selectedPosition : nil)
        updateFollowStatus(); revision &+= 1
    }
    func arrange(count: Int,center: Double,width: Double,startX: Double) {
        do {
            var value = beam; try value.arrange(count: count,startX: startX,center: center,width: width); beam = value
        } catch { surface.failure = error.localizedDescription; isPaused = true }
    }
    func advance(elapsed: Double) throws {
        if roundedComparison != nil { try roundedComparison?.advance(elapsed: elapsed,paused: isPaused,rate: playbackRate) }
        else { try comparison.advance(elapsed: elapsed,paused: isPaused,rate: playbackRate) }
        updateTracking(elapsed: isPaused ? 0 : elapsed)
    }
    func step() {
        guard canAdvance else { return }
        do {
            if isPaused, roundedComparison != nil { try roundedComparison?.step() }
            else { try comparison.singleStep(paused: isPaused) }
            updateTracking(elapsed: 0)
            revision &+= 1; updateDiagnostics()
        }
        catch { surface.failure = error.localizedDescription; isPaused = true }
    }
    func restart() {
        guard beam.isValid else { surface.failure = "Place balls outside the throat before restarting."; return }
        if roundedReturnEdge { rebuild(); return }
        do {
            try comparison.restart(paused: isPaused); surface.failure = nil
            restartID &+= 1; revision &+= 1; updateDiagnostics()
        } catch { surface.failure = error.localizedDescription; isPaused = true }
    }
    func resetCamera() {
        tracking.reset(camera: &surface.camera,preset: ellisGeometry?.camera ?? beam.geometry.camera)
        followingEnabled = false; updateFollowStatus(); revision &+= 1
    }
    func cameraForFrame() -> OrbitCamera {
        tracking.resolved(camera: surface.camera)
    }
    func recordAnnotationCamera(_ camera: OrbitCamera) {
        if surface.grid.visible, annotationCamera != camera { annotationCamera = camera }
    }
    func restoreDefaults() {
        tracking = RelaunchCameraTracking(); followingEnabled = false; updateFollowStatus(); surface.select(.wormhole)
        surface.camera = WormholeBeam().geometry.camera; showOtherRegion = true
        surface.camera.target.y = -(WormholeBeam().geometry.funnel?.depth ?? 7)
        presentation = WormholeSurfaceAppearance(); presentation.mode = .wireframe; presentation.opacity = 1
        appearance = GeodesicAppearance(); fade = TrailFade(delay: 30,duration: 30); playbackRate = 2
        trailLength = 8192; selectedBall = 0
        var settings = WormholeLaunchSettings(); settings.continuous = true; launches = settings
        beam = WormholeBeam()
    }
    private func updateTracking(elapsed: Double) {
        tracking.update(particle: selectedIsVisible ? selectedPosition : nil,elapsed: elapsed,
                        reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        updateFollowStatus()
    }
    private func updateFollowStatus() {
        let status: String
        if !isFollowing { status = "" }
        else if tracking.isWaiting { status = "Waiting for selected ball to relaunch" }
        else if tracking.isTransitioning { status = "Returning to selected ball" }
        else { status = "Following selected ball" }
        if status != followStatus { followStatus = status }
    }
    func updateDiagnostics() {
        if launches.continuous && !selectedIsVisible {
            diagnostics = "Ball \(selectedBall+1) · Waiting for launch"; return
        }
        if let roundedComparison {
            let track = roundedComparison.tracks[selectedBall]
            diagnostics = String(format: "Ball %d · %@\ns = %.2f · ΔE = %+.3e · surface error = %.3e",selectedBall+1,selectedOutcome,
                                 Double(track.solver.steps)*FixedStepClock.timestep,track.solver.energyDrift,track.solver.surfaceError)
            return
        }
        let track = comparison.tracks[selectedBall]
        diagnostics = String(format: "Ball %d · %@\ns = %.2f · ΔE = %+.3e · ΔJ = %+.3e",selectedBall+1,selectedOutcome,
                             Double(track.solver.steps)*FixedStepClock.timestep,track.solver.energyDrift,track.solver.momentumDrift)
    }
    private func rebuild() {
        do {
            if roundedReturnEdge {
                var value = try RoundedWormholeComparison(beam: beam,trailLength: trailLength,launches: launches)
                try value.advance(elapsed: 0,paused: isPaused,rate: playbackRate)
                roundedComparison = value
            } else {
                var value = try WormholeComparison(beam: beam,trailLength: trailLength,launches: launches)
                try value.advance(elapsed: 0,paused: isPaused,rate: playbackRate)
                comparison = value; roundedComparison = nil
            }
            selectedBall = min(selectedBall,beam.starts.count-1)
            surface.failure = nil; restartID &+= 1; revision &+= 1; updateDiagnostics()
        } catch { surface.failure = error.localizedDescription; isPaused = true }
    }
}
