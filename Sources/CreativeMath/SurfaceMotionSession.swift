import WorkspaceCore

// The shared viewport/transport contract for the two surface experiments. Solvers remain
// separate concrete CPU models; this is not a general physics or document interface.
@MainActor
protocol SurfaceMotionSession: AnyObject {
    var surface: SurfaceSession { get }
    var isPaused: Bool { get set }
    var restartID: UInt64 { get }
    var fade: TrailFade { get }
    var appearance: GeodesicAppearance { get }
    var renderedTrail: GeodesicTrail { get }
    var renderBatch: [GeodesicRenderTrack]? { get }
    var maximumRenderTracks: Int { get }
    var displayedParticle: SIMD3<Double>? { get }
    var depthTolerance: Float { get }
    var ellisGeometry: EllisWormhole? { get }
    var ellisAppearance: WormholeSurfaceAppearance? { get }
    var canAdvance: Bool { get }
    var annotationCamera: OrbitCamera { get }
    func advance(elapsed: Double) throws
    func restart()
    func step()
    func resetCamera()
    func cameraForFrame() -> OrbitCamera
    func recordAnnotationCamera(_ camera: OrbitCamera)
    func updateDiagnostics()
}
extension SurfaceMotionSession {
    var renderBatch: [GeodesicRenderTrack]? { nil }
    var maximumRenderTracks: Int { 1 }
    var displayedParticle: SIMD3<Double>? { nil }
    var depthTolerance: Float { 0.005 }
    var ellisGeometry: EllisWormhole? { nil }
    var ellisAppearance: WormholeSurfaceAppearance? { nil }
    var canAdvance: Bool { true }
}
