import SwiftUI
import WorkspaceCore

struct GeodesicInspector: View {
    var session: GeodesicSession
    private func angle(_ keyPath: WritableKeyPath<TorusGeodesicConfiguration, Double>) -> Binding<Double> {
        Binding(get: { session.configuration[keyPath: keyPath]*180 / .pi },set: { session.configuration[keyPath: keyPath] = $0 * .pi/180 })
    }
    var body: some View {
        VStack(alignment: .leading,spacing: 16) {
            Text("Torus Geodesics").font(Design.section)
            Text("A single particle follows the torus metric. The amber trail records its computed path; the surface grid shows coordinates.")
                .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
            HStack {
                Button(session.isPaused ? "Resume" : "Pause",systemImage: session.isPaused ? "play.fill" : "pause.fill") { session.isPaused.toggle() }
                    .accessibilityIdentifier("geodesicPause")
                Button("Step",systemImage: "forward.end") { session.step() }.disabled(!session.isPaused)
                    .help("Advance exactly 1/240 s (⌘])").accessibilityIdentifier("geodesicStep")
            }
            HStack {
                Button("Restart",systemImage: "arrow.counterclockwise") { session.restart() }
                    .help("Restart at the edited initial conditions; keep camera and pause state")
                    .accessibilityIdentifier("geodesicRestart")
                Button("Camera",systemImage: "viewfinder") { session.resetCamera() }
                    .accessibilityLabel("Reset Camera").accessibilityIdentifier("geodesicCameraReset")
            }
            Button("Restore Preset Defaults") { session.restoreDefaults() }.accessibilityIdentifier("geodesicDefaults")
            Toggle("Follow particle",isOn: Binding(get: { session.isFollowing },set: { session.isFollowing = $0 }))
                .help("Continuously tracks the particle while keeping your orbit angle and zoom. Pan adjusts framing; Reset Camera stops following. Surface occlusion remains enabled.")
                .accessibilityIdentifier("followGeodesicParticle")
            NumericControl(title: "Playback (×)",value: Binding(get: { session.playbackRate },set: { session.playbackRate = $0 }),range: 0.125...4,step: 0.125,helpText: "Simulation seconds per wall-clock second. Changes live without restarting or enlarging the integration step.")
            NumericControl(title: "Particle size (pt)",value: Binding(get: { session.appearance.particleDiameterPoints },set: { session.appearance.particleDiameterPoints = $0 }),range: 4...28,step: 1,helpText: "Marker diameter in screen points, independent of Retina scale and camera distance. Does not change the mathematical particle.")
            NumericControl(title: "Trail width (pt)",value: Binding(get: { session.appearance.trailWidthPoints },set: { session.appearance.trailWidthPoints = $0 }),range: 0.5...3,step: 0.1,helpText: "Screen-space line width. Appearance edits preserve the path and pause state.")
            NumericControl(title: "Initial u (°)",value: angle(\.initialU),range: 0...360,step: 1,helpText: "Azimuth around the symmetry axis. Mathematical angles are radians internally; controls use degrees.")
            NumericControl(title: "Initial v (°)",value: angle(\.initialV),range: 0...360,step: 1,helpText: "Angle around the tube. 0° is the outer equator; 180° is the inner equator.")
            NumericControl(title: "Launch angle (°)",value: angle(\.direction),range: -180...180,step: 1,helpText: "0° follows +u; +90° follows +v around the tube. Angle is measured in the orthonormal tangent frame, so position edits preserve launch speed.")
            NumericControl(title: "Speed",value: Binding(get: { session.configuration.speed },set: { session.configuration.speed = $0 }),range: 0.25...8,step: 0.05,helpText: "Surface distance in world units per simulation second. Editing initial conditions, speed or radii restarts the path.")
            NumericControl(title: "Major radius R",value: Binding(get: { session.configuration.torus.majorRadius },set: { session.configuration.torus.majorRadius = $0 }),range: 4...9,step: 0.1,helpText: "Radius of the tube's center circle. R always exceeds r in these ranges.")
            NumericControl(title: "Tube radius r",value: Binding(get: { session.configuration.torus.minorRadius },set: { session.configuration.torus.minorRadius = $0 }),range: 0.5...3,step: 0.05,helpText: "Radius of the tube. Radii edits update the existing M2 mesh and restart the geodesic.")
            NumericControl(title: "Trail points",value: Binding(get: { Double(session.trailLength) },set: { session.trailLength = Int($0) }),range: 256...8192,step: 256,deferred: true,helpText: "Bounded history sampled every 1/240 s. Resizing the history restarts the path.")
            NumericControl(title: "Fade Delay",value: Binding(get: { session.fade.delay },set: { session.fade.delay = $0 }),range: 0...30,step: 0.1,helpText: "Simulation seconds at full trail opacity. Pause freezes age; changing fade does not restart.")
            NumericControl(title: "Fade Duration",value: Binding(get: { session.fade.duration },set: { session.fade.duration = $0 }),range: 0...30,step: 0.1,helpText: "Seconds to fade to zero, limited by retained history. Zero cuts immediately after the delay.")
            Picker("Surface",selection: Binding(get: { session.surface.style },set: { session.surface.style = $0 })) {
                ForEach(SurfaceStyle.allCases) { Text($0.title).tag($0) }
            }
            Toggle("Coordinate grid",isOn: Binding(get: { session.surface.grid.visible },set: { session.surface.grid.visible = $0 }))
            DisclosureGroup("Diagnostics") {
                Text(session.diagnostics).font(Design.numeric).foregroundStyle(Design.secondary)
                    .fixedSize(horizontal: false,vertical: true)
                    .accessibilityIdentifier("geodesicDiagnostics")
            }
            Text("Drag to orbit · Shift-drag to pan\nScroll or pinch to zoom · ⌘0 resets camera\nSpace pauses · ⌘] steps · ⌘R restarts")
                .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
        }
        .buttonStyle(.bordered).controlSize(.large)
    }
}

struct GeodesicGalleryStudy: View {
    var open: () -> Void
    @State private var preview = GeodesicSession(preview: true)
    var body: some View {
        VStack(alignment: .leading,spacing: 24) {
            Text("Torus / The straightest path").font(Design.title).accessibilityAddTraits(.isHeader)
            SurfaceViewport(session: preview.surface,revision: preview.revision,geodesic: preview)
                .frame(height: 360).overlay(Rectangle().strokeBorder(Design.border)).allowsHitTesting(false)
            if let failure = preview.surface.failure { Text(failure).font(Design.body).foregroundStyle(Design.secondary) }
            HStack(alignment: .top,spacing: 24) {
                Text("Launch a particle in the tangent plane. Curvature alone bends its geodesic around the ring. Preview shows eight seconds of the actual solver, paused.")
                    .font(Design.body).foregroundStyle(Design.secondary).fixedSize(horizontal: false,vertical: true)
                Spacer(minLength: 16)
                Button("Open Torus Geodesics",systemImage: "arrow.right",action: open)
                    .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("openTorusGeodesics")
            }
        }
    }
}
