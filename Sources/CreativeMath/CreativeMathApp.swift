import SwiftUI

@main
struct CreativeMathApp: App {
    var body: some Scene {
        Window("Creative Math", id: "workspace") {
            WorkspaceView()
                .preferredColorScheme(.dark)
                .tint(Design.accent)
        }
        .defaultSize(width: 1440, height: 900)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            LorenzCommands()
        }
    }
}

private struct LorenzSessionKey: FocusedValueKey {
    typealias Value = LorenzSession
}

private struct SurfaceSessionKey: FocusedValueKey {
    typealias Value = SurfaceSession
}

private struct GeodesicSessionKey: FocusedValueKey { typealias Value = any SurfaceMotionSession }

extension FocusedValues {
    var geodesicSession: (any SurfaceMotionSession)? {
        get { self[GeodesicSessionKey.self] }
        set { self[GeodesicSessionKey.self] = newValue }
    }
    var surfaceSession: SurfaceSession? {
        get { self[SurfaceSessionKey.self] }
        set { self[SurfaceSessionKey.self] = newValue }
    }
    var lorenzSession: LorenzSession? {
        get { self[LorenzSessionKey.self] }
        set { self[LorenzSessionKey.self] = newValue }
    }
}

struct LorenzCommands: Commands {
    @FocusedValue(\.lorenzSession) private var session
    @FocusedValue(\.surfaceSession) private var surface
    @FocusedValue(\.geodesicSession) private var geodesic
    var body: some Commands {
        CommandMenu("Simulation") {
            Button((geodesic?.isPaused ?? session?.isPaused) == true ? "Resume" : "Pause") {
                if let geodesic { geodesic.isPaused.toggle() } else { session?.isPaused.toggle() }
            }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(geodesic?.canAdvance == false || (session == nil && geodesic == nil) || session?.failure != nil || geodesic?.surface.failure != nil)
            Button("Step") { if let geodesic { geodesic.step() } else { session?.step() } }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(geodesic?.canAdvance == false || (geodesic?.isPaused ?? session?.isPaused) != true || session?.failure != nil || geodesic?.surface.failure != nil)
            Button(geodesic == nil ? "Reset Simulation" : "Restart Simulation") { if let geodesic { geodesic.restart() } else { session?.reset() } }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(geodesic == nil && (session == nil || session?.failure != nil))
        }
        CommandMenu("Camera") {
            Button("Reset Camera") {
                if let geodesic { geodesic.resetCamera() }
                else if let surface { surface.resetCamera() }
                else { session?.resetCamera() }
            }
                .keyboardShortcut("0", modifiers: .command)
                .disabled((session == nil && surface == nil) || session?.failure != nil || surface?.failure != nil)
        }
    }
}
