import AppKit
import SwiftUI
import WorkspaceCore

// Only header/resize strips participate in mouse tracking; body controls and scrolling stay native.
struct PanelMouseRegion: NSViewRepresentable {
    var edges: PanelPlacement.Edges = []
    var onBegin: () -> Void
    var onChange: (CGSize) -> Void
    var onEnd: () -> Void
    var onDoubleClick: (() -> Void)?
    var excludesCloseButton = false

    func makeNSView(context: Context) -> MouseView { MouseView() }

    func updateNSView(_ view: MouseView, context: Context) {
        view.region = self
        view.window?.invalidateCursorRects(for: view)
    }

    final class MouseView: NSView {
        var region: PanelMouseRegion?
        private var start: CGPoint?
        private var hasDragged = false
        override var acceptsFirstResponder: Bool { false }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func hitTest(_ point: NSPoint) -> NSView? {
            let local = convert(point, from: superview)
            let button = CGRect(x: bounds.width - 40, y: (bounds.height - 28) / 2, width: 28, height: 28)
            if region?.excludesCloseButton == true && button.contains(local) { return nil }
            return super.hitTest(point)
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: resizeCursor)
        }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2, let action = region?.onDoubleClick {
                action()
                return
            }
            start = NSEvent.mouseLocation
            hasDragged = false
            region?.onBegin()
        }

        override func mouseDragged(with event: NSEvent) { updateTranslation() }

        override func mouseUp(with event: NSEvent) {
            guard start != nil else { return }
            if hasDragged { updateTranslation() }
            start = nil
            region?.onEnd()
            resizeCursor.set()
        }

        private func updateTranslation() {
            guard let start else { return }
            let point = NSEvent.mouseLocation
            guard hasDragged || hypot(point.x - start.x, point.y - start.y) >= 3 else { return }
            hasDragged = true
            if region?.edges.isEmpty == true { NSCursor.closedHand.set() }
            // Screen coordinates are +Y up; workspace coordinates are +Y down.
            region?.onChange(CGSize(width: point.x - start.x, height: start.y - point.y))
        }

        private var resizeCursor: NSCursor {
            let edges = region?.edges ?? []
            guard !edges.isEmpty else { return hasDragged && start != nil ? .closedHand : .openHand }
            if #available(macOS 15, *) {
                let position: NSCursor.FrameResizePosition
                switch edges {
                case [.top, .left]: position = .topLeft
                case [.top, .right]: position = .topRight
                case [.bottom, .left]: position = .bottomLeft
                case [.bottom, .right]: position = .bottomRight
                case .left: position = .left
                case .right: position = .right
                case .top: position = .top
                default: position = .bottom
                }
                return .frameResize(position: position, directions: .all)
            }
            if edges == .left || edges == .right { return .resizeLeftRight }
            if edges == .top || edges == .bottom { return .resizeUpDown }
            let descending = edges == [.top, .left] || edges == [.bottom, .right]
            let symbol = descending ? "arrow.up.left.and.arrow.down.right" : "arrow.up.right.and.arrow.down.left"
            guard let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) else { return .crosshair }
            return NSCursor(image: image, hotSpot: CGPoint(x: image.size.width / 2, y: image.size.height / 2))
        }
    }
}
