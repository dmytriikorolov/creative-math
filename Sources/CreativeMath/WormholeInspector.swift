import SwiftUI
import WorkspaceCore

struct WormholeInspector: View {
    var session: WormholeSession
    @State private var count = 13.0
    @State private var rowX = -18.0
    @State private var center = 0.0
    @State private var width = 9.6
    private func placeRow() { session.arrange(count: Int(count),center: center,width: width,startX: rowX) }
    var body: some View {
        VStack(alignment: .leading,spacing: 16) {
            Text("Wormhole / Compare starting positions").font(Design.section)
            Text("Balls follow the curved surface. Launches produce crossings or outward turns; variation changes only their initial conditions.")
                .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            HStack {
                Button(session.isPaused ? "Resume" : "Pause",systemImage: session.isPaused ? "play.fill" : "pause.fill") { session.isPaused.toggle() }
                    .disabled(!session.canAdvance).accessibilityIdentifier("wormholePause")
                Button("Step",systemImage: "forward.end") { session.step() }.disabled(!session.isPaused || !session.canAdvance)
                    .accessibilityIdentifier("wormholeStep")
            }
            HStack {
                Button("Restart",systemImage: "arrow.counterclockwise") { session.restart() }.accessibilityIdentifier("wormholeRestart")
                Button("Camera",systemImage: "viewfinder") { session.resetCamera() }.accessibilityLabel("Reset Camera").accessibilityIdentifier("wormholeCameraReset")
            }
            Button("Restore Preset Defaults") { session.restoreDefaults(); count = 13; rowX = -18; center = 0; width = 9.6 }.accessibilityIdentifier("wormholeDefaults")
            Picker("Selected ball",selection: Binding(get: { session.selectedBall },set: { session.selectBall($0) })) {
                ForEach(session.beam.starts.indices,id: \.self) { Text("Ball \($0+1)").tag($0) }
            }
            .accessibilityIdentifier("selectedWormholeBall")
            Text("Selected: \(session.selectedOutcome)").font(Design.numeric).foregroundStyle(Design.secondary)
            Toggle("Follow selected ball",isOn: Binding(get: { session.isFollowing },set: { session.isFollowing = $0 })).accessibilityIdentifier("followWormholeParticle")
            if session.isFollowing {
                Text(session.followStatus).font(Design.metadata).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false,vertical: true).accessibilityIdentifier("wormholeFollowStatus")
            }
            Text("Motion").font(Design.section)
            Toggle("Continuous launches",isOn: Binding(get: { session.launches.continuous },set: { session.launches.continuous = $0 }))
                .accessibilityIdentifier("wormholeContinuousLaunches")
            if session.launches.continuous {
                Toggle("Start together as a row",isOn: Binding(get: { session.launches.startTogether },set: { session.launches.startTogether = $0 }))
                    .accessibilityIdentifier("wormholeStartTogether")
                NumericControl(title: "Launch variation",value: Binding(get: { session.launches.variation },set: { session.launches.variation = $0 }),range: 0...1,step: 0.05)
                NumericControl(title: "Launch seed",value: Binding(get: { Double(session.launches.seed) },set: { session.launches.seed = UInt64($0.rounded()) }),range: 0...999999,step: 1,deferred: true)
                Text("Start together uses the exact row for the first launch. Escaped slots return with staggered, seeded variations; balls still on the surface stay. Turn it off to stagger the first launch too. Restart repeats the row and seed. Launch edits restart motion.")
                    .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            }
            NumericControl(title: "Playback (×)",value: Binding(get: { session.playbackRate },set: { session.playbackRate = $0 }),range: 0.125...16,step: 0.125)
            Text("Faster playback takes more fixed solver steps; it does not change the paths. Slow frames may limit the achieved speed.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            Text("Shape").font(Design.section)
            NumericControl(title: "Throat radius",value: Binding(get: { session.beam.geometry.throatRadius },set: { session.beam.geometry.throatRadius = $0 }),range: 1...4,step: 0.05)
            Text("Widens or narrows the opening. Shape edits restart all balls.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            NumericControl(title: "Funnel depth",value: Binding(get: { session.beam.geometry.funnel?.depth ?? 7 },set: { session.beam.geometry.funnel?.depth = $0 }),range: 2...12,step: 0.1)
            Text("Changes the bend and separation of the two regions. Motion follows the edited shape.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            Toggle("Rounded return edge (+X)",isOn: Binding(get: { session.roundedReturnEdge },set: { session.roundedReturnEdge = $0 }))
                .accessibilityIdentifier("roundedWormholeEdge")
            Text("A smooth semicircular bend joins the two sheets at the +X edge. Balls curve around it onto the other sheet; the other three edges stay open. Changing this restarts motion.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            Toggle("Show other region",isOn: Binding(get: { session.showOtherRegion || session.roundedReturnEdge },set: { session.showOtherRegion = $0 })).disabled(session.roundedReturnEdge).accessibilityIdentifier("showWormholeOtherRegion")
            Text("Shows both connected sheets, as in an embedding diagram. Hiding the lower sheet keeps the same simulation.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            DisclosureGroup("Starting positions") {
                NumericControl(title: "Balls",value: $count,range: 1...17,step: 1,deferred: true,helpText: "Number of simultaneous paths. Change the row controls, then Place starting row.")
                NumericControl(title: "Row X",value: $rowX,range: -24...(-10),step: 0.5)
                NumericControl(title: "Row offset Z",value: $center,range: -12...12,step: 0.25)
                NumericControl(title: "Row width",value: $width,range: 0...20,step: 0.2)
                Button("Place starting row") { placeRow() }.accessibilityIdentifier("placeWormholeRow")
                NumericControl(title: "Common heading (°)",value: Binding(get: { session.beam.heading*180 / .pi },set: { session.beam.heading = $0 * .pi/180 }),range: -180...180,step: 1,helpText: "0° is +X; 90° is +Z. Every ball receives this same planar heading, lifted into its tangent plane and normalized to the same surface speed.")
                DisclosureGroup("Selected ball position") {
                    NumericControl(title: "Start X",value: Binding(get: { session.beam.starts[session.selectedBall].x },set: { session.beam.starts[session.selectedBall].x = $0 }),range: -24...24,step: 0.1,helpText: "Move the selected ball's initial position. Position and geometry edits restart all balls together for comparison.")
                    NumericControl(title: "Start Z",value: Binding(get: { session.beam.starts[session.selectedBall].y },set: { session.beam.starts[session.selectedBall].y = $0 }),range: -24...24,step: 0.1)
                }
                Text("Row controls apply together with Place starting row. Individual starts and heading apply immediately and restart all balls.")
                    .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            }
            Text("Appearance").font(Design.section)
            Text("These controls change the drawing only; they do not change the shape or paths.")
                .font(Design.metadata).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            Picker("Presentation",selection: Binding(get: { session.presentation.mode },set: { session.presentation.mode = $0 })) {
                ForEach(WormholePresentation.allCases) { Text($0.title).tag($0) }
            }.accessibilityIdentifier("wormholePresentation")
            if session.presentation.mode != .trajectories {
                NumericControl(title: "Surface opacity",value: Binding(get: { session.presentation.opacity },set: { session.presentation.opacity = $0 }),range: 0...1,step: 0.05)
            }
            Toggle("Show trails",isOn: Binding(get: { session.appearance.trailVisible },set: { session.appearance.trailVisible = $0 }))
            Toggle("Show balls",isOn: Binding(get: { session.appearance.particleVisible },set: { session.appearance.particleVisible = $0 }))
            DisclosureGroup("Fine adjustments and diagnostics") {
                Toggle("Throat reference",isOn: Binding(get: { session.presentation.throatVisible },set: { session.presentation.throatVisible = $0 }))
                NumericControl(title: "Trail points",value: Binding(get: { Double(session.trailLength) },set: { session.trailLength = Int($0) }),range: 256...8192,step: 256,deferred: true)
                NumericControl(title: "Ball size (pt)",value: Binding(get: { session.appearance.particleDiameterPoints },set: { session.appearance.particleDiameterPoints = $0 }),range: 4...28,step: 1)
                NumericControl(title: "Fade Delay",value: Binding(get: { session.fade.delay },set: { session.fade.delay = $0 }),range: 0...30,step: 0.1)
                NumericControl(title: "Fade Duration",value: Binding(get: { session.fade.duration },set: { session.fade.duration = $0 }),range: 0...30,step: 0.1)
                Text(session.diagnostics).font(Design.numeric).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            }
            Text((session.roundedReturnEdge ? "The +X edge joins the sheets. Balls disappear four units beyond the other three open sides." : "Balls and trails disappear four units beyond the grid. Remaining balls keep moving. Hiding the lower sheet keeps its balls simulated.")+"\nDrag to orbit · Shift-drag to pan · Scroll/pinch to zoom · ⌘0 resets camera")
                .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true).accessibilityIdentifier("wormholeCameraHelp")
        }
        .buttonStyle(.bordered).controlSize(.large)
        .onAppear {
            let starts = session.beam.starts
            count = Double(starts.count); rowX = starts[0].x
            let zs = starts.map(\.y)
            center = ((zs.min() ?? 0)+(zs.max() ?? 0))/2
            width = (zs.max() ?? 0)-(zs.min() ?? 0)
        }
    }
}

struct WormholeGalleryStudy: View {
    var open: () -> Void
    @State private var preview = WormholeSession(preview: true)
    var body: some View {
        VStack(alignment: .leading,spacing: 24) {
            Text("Wormhole / Where do different starts lead?").font(Design.title).accessibilityAddTraits(.isHeader)
            SurfaceViewport(session: preview.surface,revision: preview.revision,geodesic: preview)
                .frame(height: 360).overlay(Rectangle().strokeBorder(Design.border)).allowsHitTesting(false)
            if let failure = preview.surface.failure { Text(failure).font(Design.body).foregroundStyle(Design.secondary) }
            HStack(alignment: .top,spacing: 24) {
                Text("A parallel row of balls approaches the original funnel. Compare paths that bend away with paths that pass through. Preview shows 24 units of actual integration, paused.")
                    .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
                Spacer(minLength: 16)
                Button("Open Wormhole",systemImage: "arrow.right",action: open).buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("openWormholeGeodesics")
            }
        }
    }
}
