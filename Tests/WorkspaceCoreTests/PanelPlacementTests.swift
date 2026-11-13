import Foundation
import CoreGraphics
import Testing
@testable import WorkspaceCore

private let workspace = CGSize(width: 1280, height: 800)
private let initial = CGRect(x: 200, y: 160, width: 304, height: 224)

@Test func dragUsesInitialFrameAndTotalTranslation() {
    let result = PanelPlacement.moved(initial, by: CGSize(width: 120, height: 80), in: workspace)
    #expect(result == CGRect(x: 320, y: 240, width: 304, height: 224))
    #expect(PanelPlacement.moved(initial, by: .zero, in: workspace) == initial)
}

@Test func dragClampsAtEveryBoundary() {
    let result = PanelPlacement.moved(initial, by: CGSize(width: -9000, height: -9000), in: workspace)
    #expect(result.origin == CGPoint(x: 16, y: 16))
    let opposite = PanelPlacement.moved(initial, by: CGSize(width: 9000, height: 9000), in: workspace)
    #expect(opposite.maxX == 1264)
    #expect(opposite.maxY == 784)
}

@Test func magneticAttractionIsContinuousAndMonotonic() {
    var previous: CGFloat = -1
    // Sample across the contact zone and the 12 pt attraction boundary.
    for step in 0...160 {
        let distance = CGFloat(step) / 10
        let result = PanelPlacement.moved(initial, by: CGSize(width: 16 + distance - initial.minX, height: 0), in: workspace)
        let offset = result.minX - 16
        #expect(offset >= previous)
        if previous >= 0 { #expect(offset - previous < 0.3) }
        #expect(offset <= distance + 0.00001)
        previous = offset
    }
    #expect(PanelPlacement.moved(initial, by: CGSize(width: 19 - initial.minX, height: 0), in: workspace).minX == 16)
    #expect(PanelPlacement.moved(initial, by: CGSize(width: 28 - initial.minX, height: 0), in: workspace).minX == 28)
}

@Test func magneticAttractionIsSymmetricForAllEdges() {
    let nearTopLeft = PanelPlacement.moved(initial, by: CGSize(width: 22 - initial.minX, height: 22 - initial.minY), in: workspace)
    let nearBottomRight = PanelPlacement.moved(initial, by: CGSize(width: 954 - initial.minX, height: 554 - initial.minY), in: workspace)
    #expect(abs((nearTopLeft.minX - 16) - (1264 - nearBottomRight.maxX)) < 0.000001)
    #expect(abs((nearTopLeft.minY - 16) - (784 - nearBottomRight.maxY)) < 0.000001)
}

@Test func oppositeMagnetsDoNotOverlapWhenPanelNearlyFillsWorkspace() {
    let size = CGSize(width: 1280, height: 680)
    var previous: CGFloat = 16
    let start = CGRect(x: 200, y: 16, width: 304, height: 640)
    for step in 0...160 {
        let result = PanelPlacement.moved(start, by: CGSize(width: 0, height: CGFloat(step) / 20), in: size)
        #expect(result.minY >= previous)
        #expect(result.minY - previous < 0.15)
        #expect(result.minY >= 16 && result.maxY <= 664)
        previous = result.minY
    }
}

@Test func repeatedDragStartsAtDisplayedFrameAndFollowsPointerDirection() {
    for x in [16.0, 16.5, 18, 22, 27, 28, 948, 954, 959.5, 960] {
        let start = CGRect(x: x, y: 160, width: 304, height: 224)
        let unchanged = PanelPlacement.moved(start, by: .zero, in: workspace)
        #expect(abs(unchanged.minX - start.minX) < 0.00001)
        let right = PanelPlacement.moved(start, by: CGSize(width: 1, height: 0), in: workspace)
        let left = PanelPlacement.moved(start, by: CGSize(width: -1, height: 0), in: workspace)
        #expect(right.minX >= start.minX - 0.00001)
        #expect(left.minX <= start.minX + 0.00001)
    }
}

@Test(arguments: PanelPlacement.Edges.handles)
func resizeKeepsOppositeEdgesFixed(edges: PanelPlacement.Edges) {
    let result = PanelPlacement.resized(initial, by: CGSize(width: 20, height: 20), edges: edges, in: workspace)
    if edges.contains(.left) { #expect(result.maxX == initial.maxX) }
    else { #expect(result.minX == initial.minX) }
    if edges.contains(.top) { #expect(result.maxY == initial.maxY) }
    else { #expect(result.minY == initial.minY) }
    if !edges.contains(.left) && !edges.contains(.right) { #expect(result.width == initial.width) }
    if !edges.contains(.top) && !edges.contains(.bottom) { #expect(result.height == initial.height) }
}

@Test func resizeFollowsPointerWithoutAccumulatingDeltas() {
    let result = PanelPlacement.resized(initial, by: CGSize(width: 80, height: 60), edges: [.right, .bottom], in: workspace)
    #expect(result == CGRect(x: 200, y: 160, width: 384, height: 284))
    let left = PanelPlacement.resized(CGRect(x: 300, y: 300, width: 400, height: 400), by: CGSize(width: -40, height: -30), edges: [.left, .top], in: workspace)
    #expect(left == CGRect(x: 260, y: 270, width: 440, height: 430))
}

@Test(arguments: PanelPlacement.Edges.handles)
func resizeHonorsLimitsAndWorkspace(edges: PanelPlacement.Edges) {
    for delta in [-10000.0, 10000.0] {
        let result = PanelPlacement.resized(initial, by: CGSize(width: delta, height: delta), edges: edges, in: workspace)
        #expect(result.width >= 280 && result.width <= 520)
        #expect(result.height >= 224 && result.height <= 640)
        #expect(result.minX >= 16 && result.maxX <= 1264)
        #expect(result.minY >= 16 && result.maxY <= 784)
    }
}

@Test func clampingFitsSmallerWorkspaceAndIsIdempotent() {
    let size = CGSize(width: 400, height: 300)
    let result = PanelPlacement.constrained(CGRect(x: 1200, y: 900, width: 520, height: 640), in: size)
    #expect(result == CGRect(x: 16, y: 16, width: 368, height: 268))
    #expect(PanelPlacement.constrained(result, in: size) == result)
    let tiny = PanelPlacement.constrained(initial, in: CGSize(width: 100, height: 100))
    #expect(tiny == CGRect(x: 16, y: 16, width: 68, height: 68))
}

@Test func invalidFrameRecoversToFiniteDefault() {
    let result = PanelPlacement.constrained(CGRect(x: CGFloat.nan, y: CGFloat.infinity, width: -40, height: 0), in: workspace)
    #expect(result == CGRect(x: 960, y: 16, width: 304, height: 224))
}

@Test func defaultSizeRestorationKeepsPositionWhenPossible() {
    let enlarged = CGRect(x: 100, y: 150, width: 520, height: 500)
    let restored = PanelPlacement.constrained(CGRect(origin: enlarged.origin, size: PanelPlacement.panelSize), in: workspace)
    #expect(restored == CGRect(x: 100, y: 150, width: 304, height: 224))
}

@Test func preferencesRoundTripPositionAndDimensions() throws {
    let name = "dev.creativemath.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    let frame = CGRect(x: 120, y: 180, width: 440, height: 360)
    PanelPreferences.save(frame, to: defaults)
    let reopened = try #require(UserDefaults(suiteName: name))
    #expect(PanelPreferences.load(from: reopened, in: workspace) == frame)
}

@Test func preferencesMigrateExistingPositionAndDefaultMissingDimensions() throws {
    let name = "dev.creativemath.tests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: name))
    defer { defaults.removePersistentDomain(forName: name) }
    #expect(PanelPreferences.load(from: defaults, in: workspace) == CGRect(x: 960, y: 16, width: 304, height: 224))
    defaults.set(80.0, forKey: "inspector.x")
    defaults.set(120.0, forKey: "inspector.y")
    #expect(PanelPreferences.load(from: defaults, in: workspace) == CGRect(x: 80, y: 120, width: 304, height: 224))
    defaults.set(-100.0, forKey: "inspector.width")
    defaults.set(9000.0, forKey: "inspector.height")
    let result = PanelPreferences.load(from: defaults, in: workspace)
    #expect(result.width == 304)
    #expect(result.height == 640)
    #expect(result.maxY <= 784)
}
