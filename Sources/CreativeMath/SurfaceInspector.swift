import SwiftUI
import WorkspaceCore

struct SurfaceInspector: View {
    var session: SurfaceSession
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Surface", selection: Binding(get: { session.preset }, set: { session.select($0) })) {
                ForEach(SurfacePreset.allCases) { Text($0.title).tag($0) }
            }
            .accessibilityIdentifier("surfacePreset")
            Text(session.preset.summary).font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Picker("Representation", selection: Binding(get: { session.style }, set: { session.style = $0 })) {
                ForEach(SurfaceStyle.allCases) { Text($0.title).tag($0) }
            }
            .accessibilityIdentifier("surfaceStyle")
            Button("Reset Camera", systemImage: "viewfinder") { session.resetCamera() }
                .accessibilityIdentifier("surfaceCameraReset")
            Button("Restore Preset Defaults") { session.select(session.preset) }
                .accessibilityIdentifier("surfaceRestoreDefaults")
            if session.preset == .wormhole {
                NumericControl(title: "Rim radius R", value: Binding(get: { session.parameters.radius }, set: { session.parameters.radius = $0 }), range: 6...14, step: 0.1, helpText: "Outer radius in world units. The rim remains at y = 0.")
                NumericControl(title: "Throat radius a", value: Binding(get: { session.parameters.throat }, set: { session.parameters.throat = $0 }), range: 0.5...4, step: 0.05, helpText: "Radius of the open lower boundary. Smaller values narrow the throat.")
                NumericControl(title: "Depth d", value: Binding(get: { session.parameters.depth }, set: { session.parameters.depth = $0 }), range: 0...12, step: 0.1, helpText: "Bend the flat annulus downward into a funnel. Zero is flat; the throat lies at y = −d.")
            } else {
                NumericControl(title: "Major radius R", value: Binding(get: { session.parameters.majorRadius }, set: { session.parameters.majorRadius = $0 }), range: 4...9, step: 0.1, helpText: "Distance from the origin to the tube's center circle.")
                NumericControl(title: "Tube radius r", value: Binding(get: { session.parameters.tubeRadius }, set: { session.parameters.tubeRadius = $0 }), range: 0.5...3, step: 0.05, helpText: "Radius of the tube. Always smaller than R, so the ring does not self-intersect.")
            }
            NumericControl(title: "Surface grid", value: Binding(get: { Double(session.surfaceDensity) }, set: { session.surfaceDensity = Int($0) }), range: 12...96, step: 2, deferred: true, helpText: "Parameter grid density: this many angular curves and half as many crosswise curves. Mesh resolution stays fixed.")
            Toggle("Coordinate grid", isOn: Binding(get: { session.grid.visible }, set: { session.grid.visible = $0 }))
                .accessibilityIdentifier("coordinateGrid")
            if session.grid.visible {
                NumericControl(title: "Grid divisions", value: Binding(get: { Double(session.grid.divisions) }, set: { session.grid.divisions = Int($0) }), range: 4...24, step: 1, deferred: true, helpText: "Divisions per half-axis over ±15 world units. Axes and tick marks share this spacing.")
                Text("Tick spacing: \(session.grid.spacing.formatted(.number.precision(.fractionLength(2)))) units · x red · y green · z blue")
                    .font(Design.metadata).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            DisclosureGroup("Mathematics") {
                Text(session.parameters.formula).font(Design.numeric).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Drag to orbit · Shift-drag to pan\nScroll or pinch to zoom · Arrow keys orbit\nWireframe hides curves behind the surface.")
                .font(Design.body).foregroundStyle(Design.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("surfaceCameraHelp")
        }
        .buttonStyle(.bordered).controlSize(.large)
        .disabled(session.failure != nil)
    }
}

struct SurfaceGalleryStudy: View {
    var open: (SurfacePreset) -> Void
    @State private var preview = SurfaceSession()
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                Text("Surfaces / Wormhole and Torus").font(Design.title).accessibilityAddTraits(.isHeader)
                Spacer()
                Picker("Surface preview", selection: Binding(get: { preview.preset }, set: { preview.select($0) })) {
                    ForEach(SurfacePreset.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented).frame(maxWidth: 240)
                .accessibilityIdentifier("gallerySurfacePreset")
            }
            SurfaceViewport(session: preview, revision: preview.revision)
                .frame(height: 360).overlay(Rectangle().strokeBorder(Design.border))
                .allowsHitTesting(false)
            if let failure = preview.failure { Text(failure).font(Design.body).foregroundStyle(Design.secondary) }
            HStack(alignment: .top, spacing: 24) {
                Text(preview.preset.summary).font(Design.body).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 16)
                VStack(alignment: .trailing, spacing: 8) {
                    Button("Open \(preview.preset.title)", systemImage: "arrow.right") { open(preview.preset) }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .accessibilityIdentifier("openSurface")

                }
            }
        }
    }
}
