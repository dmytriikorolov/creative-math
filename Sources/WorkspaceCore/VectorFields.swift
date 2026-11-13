import Foundation
import simd

public protocol VectorField2D: Sendable {
    var isValid: Bool { get }
    func vector(at point: SIMD2<Double>) -> SIMD2<Double>
}
public extension VectorField2D { var isValid: Bool { true } }

public enum VectorFieldPreset: String, CaseIterable, Identifiable, Sendable {
    case oscillator = "Harmonic oscillator", spiral = "Stable spiral", saddle = "Linear saddle", vanDerPol = "Van der Pol"
    public var id: String { rawValue }
    public var formula: String {
        switch self {
        case .oscillator: "x′ = y; y′ = −μx"
        case .spiral: "x′ = −μx−y; y′ = x−μy"
        case .saddle: "x′ = μx; y′ = −μy"
        case .vanDerPol: "x′ = y; y′ = μ(1−x²)y−x"
        }
    }
    public var defaultParameter: Double { self == .spiral ? 0.2 : 1 }
}
public struct PlanarVectorField: VectorField2D, Sendable {
    public var preset: VectorFieldPreset
    public var parameter: Double
    public init(preset: VectorFieldPreset = .oscillator,parameter: Double = 1) { self.preset = preset; self.parameter = parameter }
    public var isValid: Bool { parameter.isFinite && (0...4).contains(parameter) }
    public var domain: PlanarDomain { PlanarDomain(minimum: SIMD2(-4,-4),maximum: SIMD2(4,4)) }
    public func vector(at p: SIMD2<Double>) -> SIMD2<Double> {
        switch preset {
        case .oscillator: SIMD2(p.y,-parameter*p.x)
        case .spiral: SIMD2(-parameter*p.x-p.y,p.x-parameter*p.y)
        case .saddle: SIMD2(parameter*p.x,-parameter*p.y)
        case .vanDerPol: SIMD2(p.y,parameter*(1-p.x*p.x)*p.y-p.x)
        }
    }
}
public enum PlanarIntegrator: String, CaseIterable, Identifiable, Sendable {
    case euler = "Euler (order 1)", rk4 = "RK4 (order 4)"
    public var id: String { rawValue }
}
public struct VectorIntegrationSettings: Sendable {
    public var method: PlanarIntegrator = .rk4
    public var timestep = 1.0/120
    public var maximumSteps = 10000
    public init() {}
    public var isValid: Bool { timestep.isFinite && (0.0001...0.05).contains(timestep) && (1...20000).contains(maximumSteps) }
}
public enum VectorTrajectoryStatus: String, Sendable {
    case ready = "Ready", running = "Running", equilibrium = "Exact equilibrium"
    case stepLimit = "Step limit reached", numericalLimit = "Numerical safety limit — reduce Δt or restart"
}
public struct VectorTrajectoryPoint: Sendable {
    public let point: SIMD2<Double>
    public let time: Double
}
public enum VectorIntegrationError: Error { case invalidConfiguration }

/// Dimensionless autonomous ODE. The plot never changes the solver domain or state.
public struct VectorTrajectory<Model: VectorField2D>: Sendable {
    public let field: Model
    public let settings: VectorIntegrationSettings
    public private(set) var history: [VectorTrajectoryPoint]
    public private(set) var status: VectorTrajectoryStatus = .ready
    public private(set) var clock = FixedStepClock()
    public var current: VectorTrajectoryPoint { history[history.count-1] }
    public var steps: Int { history.count-1 }
    public var canStep: Bool { status == .ready || status == .running }
    public init(field: Model,start: SIMD2<Double>,settings: VectorIntegrationSettings = VectorIntegrationSettings()) throws {
        let vector = field.vector(at: start)
        guard field.isValid, settings.isValid, (0..<2).allSatisfy({ start[$0].isFinite && abs(start[$0]) <= 1e4 && vector[$0].isFinite }) else {
            throw VectorIntegrationError.invalidConfiguration
        }
        self.field = field; self.settings = settings; history = [VectorTrajectoryPoint(point: start,time: 0)]
    }
    public mutating func step() {
        guard canStep else { return }
        guard steps < settings.maximumSteps else { status = .stepLimit; return }
        let p = current.point, dt = settings.timestep, a = field.vector(at: p)
        if a == .zero { status = .equilibrium; return }
        let next: SIMD2<Double>
        if settings.method == .euler { next = p+a*dt }
        else {
            let b = field.vector(at: p+a*(dt/2)), c = field.vector(at: p+b*(dt/2)), d = field.vector(at: p+c*dt)
            next = p+(a+2*b+2*c+d)*(dt/6)
        }
        guard (0..<2).allSatisfy({ next[$0].isFinite && abs(next[$0]) <= 1e4 }), next != p else {
            status = .numericalLimit; return // retain the last valid state, never clamp or reseed
        }
        history.append(VectorTrajectoryPoint(point: next,time: Double(steps+1)*dt))
        status = steps == settings.maximumSteps ? .stepLimit : .running
    }
    public mutating func advance(elapsed: Double,paused: Bool = false) {
        guard canStep else { return }
        let count = clock.consume(elapsed: elapsed,paused: paused,timestep: settings.timestep)
        for _ in 0..<count { step() }
    }
}
