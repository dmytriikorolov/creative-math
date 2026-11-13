import Foundation
import simd

public enum SurfacePreset: String, CaseIterable, Identifiable, Sendable {
    case wormhole, torus
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
    public var summary: String {
        switch self {
        case .wormhole: "A fine annular grid bends into an open throat. A geometric surface of revolution, inspired by wormhole embedding diagrams; not a spacetime simulation."
        case .torus: "Two circular motions form a ring surface. Explore the major radius, tube radius and the two families of parameter curves."
        }
    }
    public var camera: OrbitCamera { OrbitCamera(yaw: 0.45, pitch: self == .wormhole ? 0.65 : 0.55, distance: 40) }
    public var parameters: SurfaceParameters { SurfaceParameters(preset: self) }
}

public struct SurfaceParameters: Equatable, Sendable {
    public var preset: SurfacePreset
    public var radius: Double = 10
    public var throat: Double = 1.6
    public var depth: Double = 7
    public var majorRadius: Double = 6
    public var tubeRadius: Double = 2
    public init(preset: SurfacePreset = .wormhole) { self.preset = preset }
    public var isValid: Bool {
        radius.isFinite && throat.isFinite && depth.isFinite && majorRadius.isFinite && tubeRadius.isFinite &&
        (6...14).contains(radius) && (0.5...4).contains(throat) && (0...12).contains(depth) &&
        (4...9).contains(majorRadius) && (0.5...3).contains(tubeRadius)
    }
    public var formula: String {
        switch preset {
        case .wormhole: "r = a cosh(v L)\ny = d(v − 1)\nL = acosh(R/a),  v ∈ [0,1]"
        case .torus: "x = (R + r cos v) cos u\ny = r sin v\nz = (R + r cos v) sin u\nu,v ∈ [0,2π]"
        }
    }
    // Right-handed world coordinates, +Y vertical. u and v are normalized to [0,1].
    public func sample(u: Double, v: Double) -> SurfaceSample {
        let angle = 2 * Double.pi * u, c = cos(angle), s = sin(angle)
        switch preset {
        case .wormhole:
            let limit = acosh(radius/throat)
            let radial = throat*cosh(v*limit)
            let radialDerivative = throat*limit*sinh(v*limit)
            // P_v × P_u, chosen upward at the outer rim. At depth=0,v=0 the
            // parametrization is singular but the geometric annulus normal is +Y.
            let normal = SIMD3(-depth*c, radialDerivative, -depth*s)
            return SurfaceSample(position: SIMD3(radial*c, depth*(v-1), radial*s),
                                 normal: Self.unit(normal, fallback: SIMD3(0,1,0)))
        case .torus:
            let theta = 2 * Double.pi * v
            let radial = majorRadius+tubeRadius*cos(theta)
            return SurfaceSample(position: SIMD3(radial*c, tubeRadius*sin(theta), radial*s),
                                 normal: SIMD3(cos(theta)*c, sin(theta), cos(theta)*s))
        }
    }
    private static func unit(_ v: SIMD3<Double>, fallback: SIMD3<Double>) -> SIMD3<Double> {
        let length = simd_length(v)
        return length > 1e-12 && length.isFinite ? v/length : fallback
    }
}

public struct SurfaceSample: Sendable {
    public var position: SIMD3<Double>
    public var normal: SIMD3<Double>
}

public struct SurfaceVertex: Sendable {
    public var position: SIMD4<Float>
    public var normal: SIMD4<Float>
    public var uv: SIMD4<Float>
}

public struct SurfaceMesh: Sendable {
    public let vertices: [SurfaceVertex]
    public let indices: [UInt32]
    public init(parameters: SurfaceParameters, columns: Int = 192, rows: Int = 96) throws {
        guard parameters.isValid, (8...256).contains(columns), (8...128).contains(rows) else { throw SurfaceError.invalidParameters }
        var vertices: [SurfaceVertex] = []; vertices.reserveCapacity((columns+1)*(rows+1))
        for row in 0...rows {
            for column in 0...columns {
                let u = Double(column)/Double(columns), v = Double(row)/Double(rows)
                let sample = parameters.sample(u: u, v: v)
                vertices.append(SurfaceVertex(position: SIMD4(SIMD3<Float>(sample.position),1),
                                              normal: SIMD4(SIMD3<Float>(sample.normal),0), uv: SIMD4(Float(u),Float(v),0,0)))
            }
        }
        var indices: [UInt32] = []; indices.reserveCapacity(columns*rows*6)
        for row in 0..<rows {
            for column in 0..<columns {
                let a = UInt32(row*(columns+1)+column), b = a+1, c = a+UInt32(columns+1), d = c+1
                // Normals are analytic; renderer is two-sided. No UV seam interpolation
                // across the wrap: duplicated endpoint vertices carry 0 and 1 separately.
                indices.append(contentsOf: parameters.preset == .wormhole ? [a,b,c,b,d,c] : [a,c,b,b,c,d])
            }
        }
        self.vertices = vertices; self.indices = indices
    }
}

public enum SurfaceStyle: String, CaseIterable, Identifiable, Sendable {
    case wireframe, shaded
    public var id: String { rawValue }
    public var title: String { self == .wireframe ? "Wireframe" : "Shaded + grid" }
}

public struct CoordinateGrid: Equatable, Sendable {
    public var visible = false
    public var divisions = 10
    public let extent: Double = 15
    public init() {}
    public var isValid: Bool { (4...24).contains(divisions) }
    public var spacing: Double { extent/Double(divisions) }
    public var segments: [GridSegment] {
        guard isValid else { return [] }
        var lines: [GridSegment] = []
        let minor = SIMD4<Float>(0.10,0.125,0.15,1)
        // Three finite coordinate planes. Their common axis lines are emitted once.
        for i in -divisions...divisions where i != 0 {
            let t = Double(i)*spacing
            for plane in 0..<3 {
                func point(_ a: Double, _ b: Double) -> SIMD3<Double> {
                    switch plane { case 0: SIMD3(a,0,b); case 1: SIMD3(a,b,0); default: SIMD3(0,a,b) }
                }
                lines.append(GridSegment(a: point(-extent,t), b: point(extent,t), color: minor))
                lines.append(GridSegment(a: point(t,-extent), b: point(t,extent), color: minor))
            }
        }
        let colors: [SIMD4<Float>] = [SIMD4(0.48,0.25,0.23,1), SIMD4(0.28,0.43,0.35,1), SIMD4(0.28,0.36,0.53,1)]
        for axis in 0..<3 {
            var a = SIMD3<Double>.zero, b = a; a[axis] = -extent; b[axis] = extent
            lines.append(GridSegment(a: a,b: b,color: colors[axis]))
            for i in -divisions...divisions where i != 0 {
                var p = SIMD3<Double>.zero; p[axis] = Double(i)*spacing
                let tickAxis = (axis+1)%3
                var q = p; p[tickAxis] = -0.12; q[tickAxis] = 0.12
                lines.append(GridSegment(a: p,b: q,color: colors[axis]))
            }
        }
        return lines
    }
}

public struct GridSegment: Sendable {
    public var a: SIMD3<Double>
    public var b: SIMD3<Double>
    public var color: SIMD4<Float>
}
public enum SurfaceError: LocalizedError {
    case invalidParameters, resourceFailure, metalUnavailable
    public var errorDescription: String? {
        switch self {
        case .invalidParameters: "Invalid surface or grid parameters."
        case .resourceFailure: "Metal could not create the surface resources."
        case .metalUnavailable: "Metal is unavailable in this session."
        }
    }
}

extension SurfaceMesh {
    public init(ellis: EllisWormhole, columns: Int = 192, rows: Int = 128) throws {
        guard ellis.isValid, (8...256).contains(columns), (8...128).contains(rows), rows.isMultiple(of: 2) else { throw SurfaceError.invalidParameters }
        if ellis.funnel?.roundedReturnEdge == true {
            let surface = RoundedWormhole(geometry: ellis)
            var vertices: [SurfaceVertex] = []
            for row in 0...rows {
                let s = 2*Double(row)/Double(rows)-1
                for column in 0...columns {
                    let phi = 2*Double.pi*Double(column)/Double(columns)
                    let outer = surface.edge/max(abs(cos(phi)),abs(sin(phi)))
                    let radius = ellis.throatRadius+(outer-ellis.throatRadius)*pow(sin(abs(s)*Double.pi/2),2)
                    let p = surface.position(x: radius*cos(phi),z: radius*sin(phi),upper: s >= 0)
                    vertices.append(SurfaceVertex(position: SIMD4(SIMD3<Float>(p),1),normal: SIMD4(SIMD3<Float>(surface.normal(at: p)),0),
                                                  uv: SIMD4(Float(column)/Float(columns),Float(row)/Float(rows),Float(surface.gridAngle(x: p.x)),0)))
                }
            }
            // Weld upper/lower vertices on the +X return edge. Other sides stay open.
            func index(_ row: Int,_ column: Int) -> UInt32 {
                let phi = 2*Double.pi*Double(column)/Double(columns)
                let joined = row == rows && cos(phi) >= abs(sin(phi))-1e-12
                return UInt32((joined ? 0 : row)*(columns+1)+column)
            }
            var indices: [UInt32] = []
            for row in 0..<rows { for column in 0..<columns {
                let a = index(row,column), b = index(row,column+1), c = index(row+1,column), d = index(row+1,column+1)
                indices.append(contentsOf: [a,c,b,b,c,d])
            } }
            self.vertices = vertices; self.indices = indices; return
        }
        let limit = asinh(ellis.extent/ellis.throatRadius)
        var vertices: [SurfaceVertex] = []; vertices.reserveCapacity((columns+1)*(rows+1))
        for row in 0...rows {
            let v = Double(row)/Double(rows)
            let w = ellis.funnel?.showsOtherRegion == false ? v*limit : (2*v-1)*limit
            let l = ellis.throatRadius*sinh(w)
            for column in 0...columns {
                let u = Double(column)/Double(columns), phi = 2*Double.pi*u
                vertices.append(SurfaceVertex(position: SIMD4(SIMD3<Float>(ellis.displayPosition(l: l,phi: phi)),1),
                                              normal: SIMD4(SIMD3<Float>(ellis.normal(l: l,phi: phi)),0),uv: SIMD4(Float(u),Float(v),0,0)))
            }
        }
        var indices: [UInt32] = []; indices.reserveCapacity(columns*rows*6)
        for row in 0..<rows { for column in 0..<columns {
            let a = UInt32(row*(columns+1)+column), b = a+1, c = a+UInt32(columns+1), d = c+1
            indices.append(contentsOf: [a,c,b,b,c,d])
        } }
        self.vertices = vertices; self.indices = indices
    }
}
