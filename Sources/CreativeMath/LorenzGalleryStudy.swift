import SwiftUI
import WorkspaceCore

struct LorenzGalleryStudy: View {
    var open: (LorenzPreset) -> Void
    @State private var selected = LorenzPreset.classic
    @State private var preview = LorenzSession(paused: true)
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lorenz / The double scroll").font(Design.title).accessibilityAddTraits(.isHeader)
                Spacer()
                Picker("Appearance", selection: $selected) {
                    ForEach(LorenzPreset.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented).frame(maxWidth: 320)
                .accessibilityIdentifier("galleryLorenzPreset")
            }
            LorenzViewport(session: preview, revision: preview.revision)
                .frame(height: 360)
                .overlay(Rectangle().strokeBorder(Design.border))
                .allowsHitTesting(false)
            if let failure = preview.failure {
                Text(failure).font(Design.body).foregroundStyle(Design.secondary)
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selected.title).font(Design.section)
                    Text(selected.summary).font(Design.body).foregroundStyle(Design.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 16)
                Button("Open \(selected.title)", systemImage: "arrow.right") { open(selected) }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .accessibilityIdentifier("openLorenz")
            }
        }
        .onChange(of: selected) { _, value in preview.select(value) }
    }
}
