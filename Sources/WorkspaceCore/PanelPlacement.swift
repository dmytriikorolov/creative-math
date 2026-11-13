import Foundation
import CoreGraphics

public enum WorkspaceScene: String, Sendable {
    case optimization
    case blank
    case triangle
    case lorenz
    case surface
    case torusGeodesics
    case wormholeGeodesics

    public var title: String {
        switch self {
        case .optimization: "Optimization Lab"
        case .blank: "Blank Scene"
        case .triangle: "Triangle Study"
        case .lorenz: "Lorenz Attractor"
        case .surface: "Parametric Surface"
        case .torusGeodesics: "Torus Geodesics"
        case .wormholeGeodesics: "Wormhole Geodesics"
        }
    }
}

public enum PanelPlacement {
    public static let margin: CGFloat = 16
    public static let snapDistance: CGFloat = 12
    public static let panelSize = CGSize(width: 304, height: 224)
    public static let minimumSize = CGSize(width: 280, height: 224)
    public static let maximumSize = CGSize(width: 520, height: 640)

    public struct Edges: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let left = Self(rawValue: 1)
        public static let right = Self(rawValue: 2)
        public static let top = Self(rawValue: 4)
        public static let bottom = Self(rawValue: 8)
        public static let handles: [Self] = [.left, .right, .top, .bottom,
                                            [.top, .left], [.top, .right], [.bottom, .left], [.bottom, .right]]
    }

    public static func constrained(_ frame: CGRect, in workspace: CGSize) -> CGRect {
        let bounds = workspaceBounds(workspace)
        let width = frame.size.width.isFinite && frame.size.width > 0 ? frame.size.width : panelSize.width
        let height = frame.size.height.isFinite && frame.size.height > 0 ? frame.size.height : panelSize.height
        let size = CGSize(width: min(max(width, minimumSize.width), maximumSize.width, bounds.width),
                          height: min(max(height, minimumSize.height), maximumSize.height, bounds.height))
        let x = frame.origin.x.isFinite ? frame.origin.x : bounds.maxX - size.width
        let y = frame.origin.y.isFinite ? frame.origin.y : bounds.minY
        return CGRect(x: min(max(x, bounds.minX), bounds.maxX - size.width),
                      y: min(max(y, bounds.minY), bounds.maxY - size.height),
                      width: size.width, height: size.height)
    }

    public static func moved(_ start: CGRect, by translation: CGSize, in workspace: CGSize) -> CGRect {
        let frame = constrained(start, in: workspace)
        let bounds = workspaceBounds(workspace)
        // Recover the pointer-space anchor so a subsequent drag never reapplies attraction
        // to an already attracted position. The displayed frame stays continuous at drag start.
        let x = unmagnetized(frame.minX, lower: bounds.minX, upper: bounds.maxX - frame.width)
        let y = unmagnetized(frame.minY, lower: bounds.minY, upper: bounds.maxY - frame.height)
        var result = constrained(CGRect(x: x + translation.width, y: y + translation.height,
                                        width: frame.width, height: frame.height), in: workspace)
        result.origin.x = magnetic(result.minX, lower: bounds.minX, upper: bounds.maxX - result.width)
        result.origin.y = magnetic(result.minY, lower: bounds.minY, upper: bounds.maxY - result.height)
        return result
    }

    public static func resized(_ start: CGRect, by translation: CGSize, edges: Edges, in workspace: CGSize) -> CGRect {
        let frame = constrained(start, in: workspace)
        let bounds = workspaceBounds(workspace)
        let minWidth = min(minimumSize.width, bounds.width)
        let minHeight = min(minimumSize.height, bounds.height)
        var left = frame.minX, right = frame.maxX, top = frame.minY, bottom = frame.maxY
        if edges.contains(.left) {
            left = min(max(left + translation.width, bounds.minX, right - maximumSize.width), right - minWidth)
        } else if edges.contains(.right) {
            right = max(min(right + translation.width, bounds.maxX, left + maximumSize.width), left + minWidth)
        }
        if edges.contains(.top) {
            top = min(max(top + translation.height, bounds.minY, bottom - maximumSize.height), bottom - minHeight)
        } else if edges.contains(.bottom) {
            bottom = max(min(bottom + translation.height, bounds.maxY, top + maximumSize.height), top + minHeight)
        }
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    private static func workspaceBounds(_ size: CGSize) -> CGRect {
        let width = size.width.isFinite ? max(0, size.width) : 0
        let height = size.height.isFinite ? max(0, size.height) : 0
        let x = min(margin, width / 2), y = min(margin, height / 2)
        return CGRect(x: x, y: y, width: max(0, width - 2 * x), height: max(0, height - 2 * y))
    }

    // Smooth attraction over 12 pt, with a 3 pt contact zone. No release-time correction.
    private static func magnetic(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        let distance = min(value - lower, upper - value)
        // Do not overlap opposite attraction zones when the panel nearly fills an axis.
        let radius = min(snapDistance, (upper - lower) / 2)
        guard radius > 0, distance < radius else { return value }
        let contact = min(3, radius / 4)
        let t = max(0, (distance - contact) / (radius - contact))
        let offset = distance * t * t * (3 - 2 * t)
        return value - lower <= upper - value ? lower + offset : upper - offset
    }

    private static func unmagnetized(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        let distance = min(value - lower, upper - value)
        let radius = min(snapDistance, (upper - lower) / 2)
        guard radius > 0, distance < radius else { return value }
        var low = min(3, radius / 4), high = radius
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if magnetic(lower + middle, lower: lower, upper: upper) - lower < distance {
                low = middle
            } else {
                high = middle
            }
        }
        let rawDistance = (low + high) / 2
        return value - lower <= upper - value ? lower + rawDistance : upper - rawDistance
    }
}

public enum PanelPreferences {
    public static func load(from defaults: UserDefaults, in workspace: CGSize) -> CGRect {
        let width = defaults.object(forKey: "inspector.width") == nil ? PanelPlacement.panelSize.width : defaults.double(forKey: "inspector.width")
        let height = defaults.object(forKey: "inspector.height") == nil ? PanelPlacement.panelSize.height : defaults.double(forKey: "inspector.height")
        let x = defaults.double(forKey: "inspector.x")
        let y = defaults.double(forKey: "inspector.y")
        let hasPosition = defaults.object(forKey: "inspector.x") != nil && defaults.object(forKey: "inspector.y") != nil && x >= 0 && y >= 0
        return PanelPlacement.constrained(CGRect(x: hasPosition ? x : .nan, y: hasPosition ? y : .nan,
                                                 width: width, height: height), in: workspace)
    }

    public static func save(_ frame: CGRect, to defaults: UserDefaults) {
        defaults.set(frame.origin.x, forKey: "inspector.x")
        defaults.set(frame.origin.y, forKey: "inspector.y")
        defaults.set(frame.width, forKey: "inspector.width")
        defaults.set(frame.height, forKey: "inspector.height")
    }
}
