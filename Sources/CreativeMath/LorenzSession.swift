import Foundation
import Observation
import WorkspaceCore

@MainActor @Observable
final class LorenzSession {
    var configuration: LorenzConfiguration { didSet { revision &+= 1 } }
    var appearance: LorenzAppearance { didSet { revision &+= 1 } }
    var isPaused: Bool { didSet { revision &+= 1 } }
    var speed = 1.0 { didSet { revision &+= 1 } }
    private(set) var preset: LorenzPreset
    private(set) var resetID: UInt64 = 0
    private(set) var stepID: UInt64 = 0
    private(set) var cameraResetID: UInt64 = 0
    private(set) var revision: UInt64 = 0
    var failure: String?
    var timing = "Timing not measured"

    init(preset: LorenzPreset = .classic, paused: Bool = false) {
        self.preset = preset; configuration = preset.configuration; appearance = preset.appearance; isPaused = paused
    }
    func select(_ value: LorenzPreset) {
        preset = value; configuration = value.configuration; appearance = value.appearance; speed = 1
        reset(); resetCamera()
    }
    func reset() { resetID &+= 1; revision &+= 1 }
    func step() { if isPaused { stepID &+= 1; revision &+= 1 } }
    func resetCamera() { cameraResetID &+= 1; revision &+= 1 }
}
