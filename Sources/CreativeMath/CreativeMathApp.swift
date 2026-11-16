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

private struct PlanarSessionKey: FocusedValueKey { typealias Value = any PlanarTransportSession }

private struct GeodesicSessionKey: FocusedValueKey { typealias Value = any SurfaceMotionSession }

extension FocusedValues {
    var planarSession: (any PlanarTransportSession)? {
        get { self[PlanarSessionKey.self] }
        set { self[PlanarSessionKey.self] = newValue }
    }
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
    @FocusedValue(\.planarSession) private var planar
    var body: some Commands {
        CommandMenu("Simulation") {
            Button(planar.map { $0.isRunning ? "Pause" : "Run" } ?? ((geodesic?.isPaused ?? session?.isPaused) == true ? "Resume" : "Pause")) {
                if let planar { planar.isRunning.toggle() }
                else if let geodesic { geodesic.isPaused.toggle() } else { session?.isPaused.toggle() }
            }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(planar.map { !$0.canStep } ?? (geodesic?.canAdvance == false || (session == nil && geodesic == nil) || session?.failure != nil || geodesic?.surface.failure != nil))
            Button("Step") { if let planar { planar.step() } else if let geodesic { geodesic.step() } else { session?.step() } }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(planar.map { $0.isRunning || !$0.canStep } ?? (geodesic?.canAdvance == false || (geodesic?.isPaused ?? session?.isPaused) != true || session?.failure != nil || geodesic?.surface.failure != nil))
            Button(geodesic == nil ? "Reset Simulation" : "Restart Simulation") { if let planar { planar.restart() } else if let geodesic { geodesic.restart() } else { session?.reset() } }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(planar == nil && geodesic == nil && (session == nil || session?.failure != nil))
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
