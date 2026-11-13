import SwiftUI
import WorkspaceCore

struct LorenzInspector: View {
    var session: LorenzSession
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Preset", selection: Binding(get: { session.preset }, set: { session.select($0) })) {
                ForEach(LorenzPreset.allCases) { Text($0.title).tag($0) }
            }
            .accessibilityIdentifier("lorenzPreset")
            Text(session.preset.summary)
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("All three presets start with the same Lorenz equations and parameters. Some parameter settings converge to an equilibrium: trails then shrink and can disappear as motion stops and older samples fade.")
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(session.isPaused ? "Resume" : "Pause", systemImage: session.isPaused ? "play.fill" : "pause.fill") { session.isPaused.toggle() }
                    .accessibilityIdentifier("lorenzPause")
                Button("Step", systemImage: "forward.end") { session.step() }
                    .help("Advance one fixed step (⌘])")
                    .disabled(!session.isPaused)
                    .accessibilityIdentifier("lorenzStep")
            }
            HStack {
                Button("Restart", systemImage: "arrow.counterclockwise") { session.reset() }
                    .accessibilityLabel("Reset Simulation")
                    .help("Rebuild the same seeded trajectories and history using the current parameters")
                    .accessibilityIdentifier("lorenzReset")
                Button("Camera", systemImage: "viewfinder") { session.resetCamera() }
                    .accessibilityLabel("Reset Camera")
                    .help("Restore orbit, pan and zoom to the preset's starting view")
                    .accessibilityIdentifier("cameraReset")
            }
            Button("Restore Preset Defaults") { session.select(session.preset) }
                .help("Restore this preset's parameters, appearance, speed and camera, then restart its seeded paths. Keeps the current pause state.")
                .accessibilityIdentifier("restorePresetDefaults")
            NumericControl(title: "σ", value: Binding(get: { session.configuration.parameters.sigma }, set: { session.configuration.parameters.sigma = $0 }), range: 1...30, step: 0.1, helpText: "Sigma controls how quickly x follows y: dx/dt = σ(y − x).")
            NumericControl(title: "ρ", value: Binding(get: { session.configuration.parameters.rho }, set: { session.configuration.parameters.rho = $0 }), range: 0...60, step: 0.1, helpText: "Rho controls the drive in the y direction through x(ρ − z). Changing it changes the flow's structure.")
            NumericControl(title: "β", value: Binding(get: { session.configuration.parameters.beta }, set: { session.configuration.parameters.beta = $0 }), range: 0.1...10, step: 0.01, helpText: "Beta controls how strongly z decays through −βz in dz/dt = xy − βz.")
            NumericControl(title: "Trajectories", value: Binding(get: { Double(session.configuration.trajectoryCount) }, set: { session.configuration.trajectoryCount = Int($0.rounded()) }), range: 1...128, step: 1, deferred: true, helpText: "Number of independent paths, starting slightly apart. More paths reveal how nearby motions separate. Changing this restarts the paths.")
            NumericControl(title: "Trail points", value: Binding(get: { Double(session.configuration.trailLength) }, set: { session.configuration.trailLength = Int($0.rounded()) }), range: 256...8192, step: 256, deferred: true, helpText: "Maximum history kept for each path, sampled 240 times per simulation-time unit. More points show longer trails and use more memory. Changing this restarts the paths.")
            NumericControl(title: "Speed", value: Binding(get: { session.speed }, set: { session.speed = $0 }), range: 0.125...4, step: 0.125, helpText: "Simulation-time units advanced per second. This changes playback speed, while each integration step stays the same size.")
            NumericControl(title: "Fade Delay", value: Binding(get: { session.appearance.fade.delay }, set: { session.appearance.fade.delay = $0 }), range: 0...30, step: 0.1, helpText: "Simulation-time units at full preset opacity before fading starts. Pausing freezes age.")
            NumericControl(title: "Fade Duration", value: Binding(get: { session.appearance.fade.duration }, set: { session.appearance.fade.duration = $0 }), range: 0...30, step: 0.1, helpText: "Simulation-time units for a smooth fade to zero. Zero gives an immediate cut after the delay.")
            if session.appearance.representation == .ribbon {
                NumericControl(title: "Ribbon Width", value: Binding(get: { session.appearance.ribbonWidth }, set: { session.appearance.ribbonWidth = $0 }), range: 0.04...1.2, step: 0.02, helpText: "Width in Lorenz world units. The ribbon turns in three dimensions; its apparent width depends on orientation and distance.")
            }
            Text("Visible history: \((Double(session.configuration.trailLength-1)*LorenzConfiguration.timestep).formatted(.number.precision(.fractionLength(2)))) time units. Older samples leave the buffer with a short taper.")
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Restart rebuilds the same seeded paths with your current settings and a filled trail. It keeps your camera and pause state. Restore Preset Defaults resets the controls, speed and camera too. Model edits continue the paths and clear their trails.")
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            DisclosureGroup("Diagnostics") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RK4 · Δt = 1/240")
                    Text("Seed \(String(session.configuration.seed, radix: 16).uppercased())")
                    Text(String(format: "History %.2f MiB", Double(session.configuration.historyBytes)/1048576))
                    Text(session.isPaused ? "Paused" : session.timing)
                    Text("Non-finite paths restart individually; their old trails are discarded.")
                }
                .font(Design.numeric).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Text("Drag to orbit · Shift-drag to pan\nScroll or pinch to zoom")
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("inspectorCameraHelp")
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(session.failure != nil)
    }
}

struct NumericControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var deferred = false
    var significantDigits = 6
    var helpText = ""
    @State private var text = ""
    @State private var originalText = ""
    @State private var sliderValue: Double?
    @State private var invalid = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).help(helpText)
                Spacer()
                TextField(title, text: $text)
                    .font(Design.numeric).multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder).frame(width: 88).frame(minHeight: 28)
                    .focused($focused)
                    .foregroundStyle(invalid ? Design.error : Design.primary)
                    .accessibilityLabel(title)
                    .help(helpText)
                    .accessibilityHint(helpText)
                    .onSubmit { commit() }
                    .onExitCommand { synchronize(); focused = false }
                    .onChange(of: focused) { _, active in
                        if active { originalText = text } else { commit() }
                    }
            }
            Slider(value: Binding(get: { deferred ? sliderValue ?? value : value }, set: {
                if deferred { sliderValue = $0 } else { value = $0 }
            }), in: range, step: step, onEditingChanged: { editing in
                if !editing && deferred { value = sliderValue ?? value }
            })
            .accessibilityLabel("\(title) slider")
            if !helpText.isEmpty {
                Text(helpText)
                    .font(Design.body).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if invalid {
                Text("\(deferred ? "Enter a whole number in" : "Enter") \(range.lowerBound.formatted())–\(range.upperBound.formatted()).")
                    .font(Design.metadata).foregroundStyle(Design.secondary)
            }
        }
        .onAppear { synchronize() }
        .onChange(of: value) { _, newValue in
            sliderValue = newValue
            if !focused { synchronize() }
        }
        .onChange(of: sliderValue) { _, draft in
            if deferred, !focused, let draft {
                text = String(format: "%.\(significantDigits)g", draft); originalText = text; invalid = false
            }
        }
    }
    private func synchronize() {
        text = String(format: "%.\(significantDigits)g", value); originalText = text
        sliderValue = value; invalid = false
    }
    private func commit() {
        guard text != originalText else { return }
        guard let parsed = Double(text), parsed.isFinite, range.contains(parsed) else { invalid = true; return }
        guard !deferred || parsed.rounded() == parsed else { invalid = true; return }
        value = parsed; synchronize()
    }
}
