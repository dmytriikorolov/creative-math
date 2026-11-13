import Foundation

public struct PlanarDomain: Sendable, Equatable {
    public var minimum: SIMD2<Double>
    public var maximum: SIMD2<Double>
    public init(minimum: SIMD2<Double> = SIMD2(-3,-3),maximum: SIMD2<Double> = SIMD2(3,3)) {
        self.minimum = minimum; self.maximum = maximum
    }
    public var span: SIMD2<Double> { maximum-minimum }
    public var isValid: Bool {
        (0..<2).allSatisfy { minimum[$0].isFinite && maximum[$0].isFinite && maximum[$0] > minimum[$0] && span[$0].isFinite }
    }
    public func contains(_ point: SIMD2<Double>) -> Bool {
        (0..<2).allSatisfy { point[$0].isFinite && point[$0] >= minimum[$0] && point[$0] <= maximum[$0] }
    }
}
public struct LevelSegment: Sendable {
    public let a: SIMD2<Double>
    public let b: SIMD2<Double>
    public let level: Double
}
/// Uniform samples and piecewise-linear level sets from the same objective.
/// Two triangles per cell avoid ambiguous marching-square saddle cases.
public struct ObjectiveGrid: Sendable {
    public let domain: PlanarDomain
    public let resolution: Int
    public let values: [Double]
    public let range: ClosedRange<Double>
    public let levels: [Double]
    public let contours: [LevelSegment]
    public init<Model: Objective2D>(objective: Model,domain: PlanarDomain,resolution: Int = 64) throws {
        guard domain.isValid, (8...128).contains(resolution) else { throw OptimizationError.invalidConfiguration }
        self.domain = domain; self.resolution = resolution
        var points: [SIMD2<Double>] = [], values: [Double] = []
        for y in 0...resolution { for x in 0...resolution {
            let p = domain.minimum+domain.span*SIMD2(Double(x),Double(y))/Double(resolution)
            let value = objective.sample(at: p).value
            guard value.isFinite else { throw OptimizationError.invalidConfiguration }
            points.append(p); values.append(value)
        } }
        self.values = values
        let low = values.min()!, high = values.max()!
        guard (high-low).isFinite else { throw OptimizationError.invalidConfiguration }
        range = low...high
        // Quadratic spacing reveals the low-value valley while remaining explicit.
        levels = (1...12).map { low+(high-low)*pow(Double($0)/13,2) }
        var segments: [LevelSegment] = []
        for y in 0..<resolution { for x in 0..<resolution {
            let a = y*(resolution+1)+x, b = a+1, c = a+resolution+1, d = c+1
            for ids in [[a,b,d],[a,d,c]] { for level in levels {
                var intersections: [SIMD2<Double>] = []
                for i in 0..<3 {
                    let j = ids[i], k = ids[(i+1)%3], v = values[j], w = values[k]
                    if (v < level) != (w < level) {
                        intersections.append(points[j]+(points[k]-points[j])*((level-v)/(w-v)))
                    }
                }
                if intersections.count == 2 { segments.append(LevelSegment(a: intersections[0],b: intersections[1],level: level)) }
            } }
        } }
        contours = segments
    }
}
