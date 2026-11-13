import Foundation
import simd

public struct ObjectiveSample: Sendable {
    public var value: Double
    public var gradient: SIMD2<Double>
    public var hessian: simd_double2x2
    public init(value: Double,gradient: SIMD2<Double>,hessian: simd_double2x2) {
        self.value = value; self.gradient = gradient; self.hessian = hessian
    }
    public var isFinite: Bool {
        value.isFinite && (0..<2).allSatisfy { gradient[$0].isFinite && hessian[$0].x.isFinite && hessian[$0].y.isFinite }
    }
    public var minimumCurvature: Double {
        let a = hessian[0].x, b = hessian[0].y, d = hessian[1].y
        return (a+d)/2-hypot((a-d)/2,b)
    }
}

/// Numerical consumers share one objective definition with plotting and diagnostics.
public protocol Objective2D: Sendable {
    func sample(at point: SIMD2<Double>) -> ObjectiveSample
}

public enum ObjectivePreset: String, CaseIterable, Identifiable, Objective2D {
    case quadratic = "Convex quadratic", illConditioned = "Ill-conditioned quadratic"
    case rosenbrock = "Rosenbrock", doubleWell = "Double well", saddle = "Saddle"
    public var id: String { rawValue }
    public var formula: String {
        switch self {
        case .quadratic: "f(x,y) = (x² + 4y²)/2"
        case .illConditioned: "f(x,y) = (x² + 100y²)/2"
        case .rosenbrock: "f(x,y) = (1−x)² + 100(y−x²)²"
        case .doubleWell: "f(x,y) = (x²−1)² + y²"
        case .saddle: "f(x,y) = (x²−y²)/2 (unbounded below)"
        }
    }
    public var start: SIMD2<Double> { self == .rosenbrock ? SIMD2(-1.2,1) : SIMD2(-2,1.5) }
    public var domain: PlanarDomain { self == .rosenbrock ? PlanarDomain(minimum: SIMD2(-2,-1),maximum: SIMD2(2,3)) : PlanarDomain() }
    public func sample(at p: SIMD2<Double>) -> ObjectiveSample {
        let x = p.x, y = p.y
        let value: Double, gradient: SIMD2<Double>, xx: Double, xy: Double, yy: Double
        switch self {
        case .quadratic, .illConditioned:
            let k = self == .quadratic ? 4.0 : 100.0
            value = (x*x+k*y*y)/2; gradient = SIMD2(x,k*y); xx = 1; xy = 0; yy = k
        case .rosenbrock:
            let r = y-x*x
            value = (1-x)*(1-x)+100*r*r
            gradient = SIMD2(2*(x-1)-400*x*r,200*r)
            xx = 2-400*y+1200*x*x; xy = -400*x; yy = 200
        case .doubleWell:
            value = (x*x-1)*(x*x-1)+y*y
            gradient = SIMD2(4*x*(x*x-1),2*y); xx = 12*x*x-4; xy = 0; yy = 2
        case .saddle:
            value = (x*x-y*y)/2; gradient = SIMD2(x,-y); xx = 1; xy = 0; yy = -1
        }
        return ObjectiveSample(value: value,gradient: gradient,hessian: simd_double2x2(columns: (SIMD2(xx,xy),SIMD2(xy,yy))))
    }
}

public enum OptimizationMethod: String, CaseIterable, Identifiable, Sendable {
    case gradient = "Gradient descent", momentum = "Momentum", newton = "Safeguarded Newton"
    public var id: String { rawValue }
}
public struct OptimizationSettings: Sendable {
    public var method: OptimizationMethod = .gradient
    public var stepSize = 0.1
    public var momentum = 0.8
    public var tolerance = 1e-6
    public var maximumIterations = 2000
    public init() {}
    public var isValid: Bool {
        stepSize.isFinite && (1e-6...2).contains(stepSize) && momentum.isFinite && (0...0.99).contains(momentum) &&
        tolerance.isFinite && (1e-12...0.1).contains(tolerance) && (1...20000).contains(maximumIterations)
    }
}
public enum OptimizationStatus: String, Sendable {
    case ready = "Ready", running = "Running", converged = "Gradient tolerance reached"
    case nonminimum = "Stationary point with negative curvature"
    case iterationLimit = "Iteration limit", lineSearchFailed = "Line search failed"
    case numericalLimit = "Numerical safety limit", stalled = "Step below numerical resolution"
}
public struct OptimizationRecord: Sendable {
    public let point: SIMD2<Double>
    public let value: Double
    public let gradientNorm: Double
    public let stepSize: Double
    public let iteration: Int
    public let hessianShift: Double
}
public enum OptimizationError: Error { case invalidConfiguration }

/// Iterations are discrete mathematical steps, never physical timesteps. Double
/// precision; no stochastic terms. Traces include the initial point and are bounded.
public struct OptimizationRun<Model: Objective2D>: Sendable {
    public let objective: Model
    public let settings: OptimizationSettings
    public private(set) var records: [OptimizationRecord]
    public private(set) var status: OptimizationStatus = .ready
    private var velocity = SIMD2<Double>.zero
    public var current: OptimizationRecord { records[records.count-1] }
    public var canStep: Bool { status == .ready || status == .running }
    public init(objective: Model,start: SIMD2<Double>,settings: OptimizationSettings = OptimizationSettings()) throws {
        let sample = objective.sample(at: start)
        guard settings.isValid, (0..<2).allSatisfy({ start[$0].isFinite && abs(start[$0]) <= 1e6 }), sample.isFinite else {
            throw OptimizationError.invalidConfiguration
        }
        self.objective = objective; self.settings = settings
        records = [OptimizationRecord(point: start,value: sample.value,gradientNorm: simd_length(sample.gradient),stepSize: 0,iteration: 0,hessianShift: 0)]
    }
    public mutating func step() {
        guard canStep else { return }
        let old = current, sample = objective.sample(at: old.point)
        guard sample.isFinite else { status = .numericalLimit; return }
        if old.gradientNorm <= settings.tolerance {
            status = sample.minimumCurvature < -1e-8 ? .nonminimum : .converged; return
        }
        guard old.iteration < settings.maximumIterations else { status = .iterationLimit; return }
        var direction = -sample.gradient, shift = 0.0
        if settings.method == .momentum {
            // Heavy-ball displacement, restarted if it ceases to be a descent direction.
            direction = settings.momentum*velocity-settings.stepSize*sample.gradient
            if dot(direction,sample.gradient) >= 0 { direction = -settings.stepSize*sample.gradient }
        } else if settings.method == .newton {
            // Shift the Hessian to positive definiteness before solving the 2×2 system.
            shift = max(0,1e-4-sample.minimumCurvature)
            let a = sample.hessian[0].x+shift, b = sample.hessian[0].y, d = sample.hessian[1].y+shift
            let determinant = a*d-b*b
            if determinant.isFinite && determinant > 1e-15 {
                direction = SIMD2(-d*sample.gradient.x+b*sample.gradient.y,b*sample.gradient.x-a*sample.gradient.y)/determinant
            }
        }
        if settings.method == .newton && (!(0..<2).allSatisfy({ direction[$0].isFinite }) || dot(direction,sample.gradient) >= 0) {
            direction = -sample.gradient
        }
        var alpha = settings.method == .momentum ? 1 : settings.stepSize
        let slope = dot(sample.gradient,direction)
        guard slope.isFinite, slope < 0 else { status = .numericalLimit; return }
        for _ in 0..<48 {
            let point = old.point+alpha*direction
            if (0..<2).allSatisfy({ point[$0].isFinite && abs(point[$0]) <= 1e6 }) {
                let next = objective.sample(at: point)
                if next.isFinite && next.value <= sample.value+1e-4*alpha*slope {
                    guard point != old.point else { status = .stalled; return }
                    velocity = point-old.point
                    records.append(OptimizationRecord(point: point,value: next.value,gradientNorm: simd_length(next.gradient),
                                                      stepSize: alpha*(settings.method == .momentum ? settings.stepSize : 1),
                                                      iteration: old.iteration+1,hessianShift: shift))
                    status = .running
                    if current.gradientNorm <= settings.tolerance {
                        status = next.minimumCurvature < -1e-8 ? .nonminimum : .converged
                    } else if current.iteration == settings.maximumIterations { status = .iterationLimit }
                    return
                }
            }
            alpha *= 0.5
        }
        status = .lineSearchFailed
    }
}
