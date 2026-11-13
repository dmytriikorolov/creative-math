import Observation
import WorkspaceCore

@MainActor @Observable
final class SurfaceSession {
    var parameters: SurfaceParameters { didSet { revision &+= 1 } }
    var camera: OrbitCamera { didSet { revision &+= 1 } }
    var style: SurfaceStyle = .wireframe { didSet { revision &+= 1 } }
    var surfaceDensity = 48 { didSet { revision &+= 1 } }
    var grid = CoordinateGrid() { didSet { revision &+= 1 } }
    private(set) var revision: UInt64 = 0
    var failure: String?
    var preset: SurfacePreset { parameters.preset }
    init(preset: SurfacePreset = .wormhole) { parameters = preset.parameters; camera = preset.camera }
    func select(_ preset: SurfacePreset) {
        parameters = preset.parameters; camera = preset.camera
        style = .wireframe; surfaceDensity = 48; grid = CoordinateGrid()
    }
    func resetCamera() { camera = preset.camera }
}
