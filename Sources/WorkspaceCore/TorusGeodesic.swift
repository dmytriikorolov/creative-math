import Foundation
import simd

public struct TorusMetric: Equatable, Sendable {
    public var majorRadius: Double
    public var minorRadius: Double
    public init(majorRadius: Double = 6, minorRadius: Double = 2) {
        self.majorRadius = majorRadius; self.minorRadius = minorRadius
    }
    public var isValid: Bool {
        majorRadius.isFinite && minorRadius.isFinite && majorRadius > minorRadius && minorRadius > 0 &&
        (majorRadius+minorRadius).isFinite
    }
    public func metric(v: Double) -> SIMD2<Double> {
        let a = majorRadius+minorRadius*cos(v)
        return SIMD2(a*a,minorRadius*minorRadius)
    }
    // Standard mathematical coordinates: symmetry axis +Z.
    public func position(u: Double, v: Double) -> SIMD3<Double> {
        let a = majorRadius+minorRadius*cos(v)
        return SIMD3(a*cos(u),a*sin(u),minorRadius*sin(v))
    }
    // Existing M2 renderer uses +Y as its vertical axis.
    public func displayPosition(u: Double, v: Double) -> SIMD3<Double> {
        let p = position(u: u,v: v); return SIMD3(p.x,p.z,p.y)
    }
    public func speedSquared(_ state: SIMD4<Double>) -> Double {
        let g = metric(v: state.y); return g.x*state.z*state.z+g.y*state.w*state.w
    }
    public func angularMomentum(_ state: SIMD4<Double>) -> Double { metric(v: state.y).x*state.z }
    // State = (u,v,du/dt,dv/dt). Nonzero symbols: Γu_uv=Γu_vu=-r sin(v)/A,
    // Γv_uu=A sin(v)/r, A=R+r cos(v). See docs/evidence/m3.1-geodesics.md.
    public func derivative(_ state: SIMD4<Double>) -> SIMD4<Double> {
        let a = majorRadius+minorRadius*cos(state.y), s = Self.periodicSin(state.y)
        return SIMD4(state.z,state.w,2*minorRadius*s/a*state.z*state.w,-a*s/minorRadius*state.z*state.z)
    }
    public static func wrap(_ angle: Double) -> Double {
        guard angle.isFinite else { return .nan }
        let period = 2*Double.pi
        var value = angle.truncatingRemainder(dividingBy: period)
        if value >= .pi { value -= period }
        if value < -.pi { value += period }
        return value
    }
    // Preserve exact invariant equators/cardinal launch angles. No epsilon snapping:
    // floating-point sin(π) otherwise seeds spurious motion on the unstable inner equator.
    public static func periodicSin(_ angle: Double) -> Double {
        angle == 0 || abs(angle) == .pi ? 0 : sin(angle)
    }
}

public struct TorusGeodesicConfiguration: Equatable, Sendable {
    public static let timestep = FixedStepClock.timestep
    public var torus = TorusMetric()
    public var initialU: Double = .pi/6
    public var initialV: Double = .pi/8
    public var direction: Double = 65 * .pi/180
    public var speed: Double = 4
    public init() {}
    public var isValid: Bool {
        torus.isValid && (4...9).contains(torus.majorRadius) && (0.5...3).contains(torus.minorRadius) &&
        initialU.isFinite && initialV.isFinite && direction.isFinite && speed.isFinite &&
        (0...2*Double.pi).contains(initialU) && (0...2*Double.pi).contains(initialV) &&
        (-Double.pi...Double.pi).contains(direction) && (0.25...8).contains(speed)
    }
    public var initialState: SIMD4<Double> {
        let u = TorusMetric.wrap(initialU), v = TorusMetric.wrap(initialV)
        let a = torus.majorRadius+torus.minorRadius*cos(v)
        return SIMD4(u,v,speed*cos(direction)/a,speed*TorusMetric.periodicSin(direction)/torus.minorRadius)
    }
}

public struct TorusGeodesicSolver: Sendable {
    public let configuration: TorusGeodesicConfiguration
    public private(set) var state: SIMD4<Double>
    public private(set) var steps: UInt64 = 0
    public init(configuration: TorusGeodesicConfiguration) throws {
        guard configuration.isValid else { throw GeodesicError.invalidConfiguration }
        self.configuration = configuration; state = configuration.initialState
    }
    public var position: SIMD3<Double> { configuration.torus.displayPosition(u: state.x,v: state.y) }
    public var relativeSpeedDrift: Double { sqrt(configuration.torus.speedSquared(state))/configuration.speed-1 }
    public mutating func restart() { state = configuration.initialState; steps = 0 }
    public mutating func advance(steps count: Int, dt: Double = TorusGeodesicConfiguration.timestep) throws {
        guard (0...1_000_000).contains(count), dt.isFinite, dt > 0, dt <= 0.1 else { throw GeodesicError.invalidConfiguration }
        for _ in 0..<count {
            let m = configuration.torus
            let a = m.derivative(state), b = m.derivative(state+a*(dt/2))
            let c = m.derivative(state+b*(dt/2)), d = m.derivative(state+c*dt)
            let weighted: SIMD4<Double> = (a+b*2)+(c*2+d)
            var next = state+weighted*(dt/6)
            next.x = TorusMetric.wrap(next.x); next.y = TorusMetric.wrap(next.y)
            guard (0..<4).allSatisfy({ next[$0].isFinite }),
                  abs(sqrt(m.speedSquared(next))/configuration.speed-1) < 0.02 else { throw GeodesicError.unstableIntegration }
            state = next; steps += 1
        }
    }
}

// Fixed-capacity ring: xyz are mapped surface positions; w is reserved. Age is computed
// from integer sample distance, so no absolute Float timestamp grows without bound.
public struct GeodesicTrail: Sendable {
    public private(set) var points: [SIMD4<Float>]
    public private(set) var head = 0
    public private(set) var count = 0
    public init(capacity: Int) throws {
        guard (256...8192).contains(capacity) else { throw GeodesicError.invalidConfiguration }
        points = Array(repeating: .zero,count: capacity)
    }
    public mutating func append(_ position: SIMD3<Double>) {
        if count > 0 { head = (head+1)%points.count }
        points[head] = SIMD4(SIMD3<Float>(position),0); count = min(count+1,points.count)
    }
    public func point(oldestIndex: Int) -> SIMD4<Float>? {
        guard (0..<count).contains(oldestIndex) else { return nil }
        return points[(head+points.count+1-count+oldestIndex)%points.count]
    }
}

public struct GeodesicPlayback: Sendable {
    public private(set) var solver: TorusGeodesicSolver
    public private(set) var trail: GeodesicTrail
    public private(set) var clock = FixedStepClock()
    public var isPaused = false
    public var playbackRate: Double = 1
    public init(configuration: TorusGeodesicConfiguration, trailLength: Int = 8192) throws {
        solver = try TorusGeodesicSolver(configuration: configuration)
        trail = try GeodesicTrail(capacity: trailLength); trail.append(solver.position)
    }
    public mutating func restart() {
        solver.restart(); clock.reset()
        // Reuse ring allocation, invalidating its logical history.
        trail.reset(to: solver.position)
    }
    public mutating func advance(elapsed: Double) throws {
        guard playbackRate.isFinite, (0.125...4).contains(playbackRate) else { throw GeodesicError.invalidConfiguration }
        try integrate(clock.consume(elapsed: elapsed,speed: playbackRate,paused: isPaused))
    }
    public mutating func singleStep() throws { if isPaused { try integrate(1) } }
    private mutating func integrate(_ count: Int) throws {
        for _ in 0..<count { try solver.advance(steps: 1); trail.append(solver.position) }
    }
}

extension GeodesicTrail {
    public mutating func reset(to position: SIMD3<Double>) { head = 0; count = 0; append(position) }
}

public enum GeodesicError: LocalizedError {
    case invalidConfiguration, unstableIntegration
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "Invalid torus geodesic initial conditions."
        case .unstableIntegration: "Geodesic integration became non-finite or exceeded 2% speed drift. Restart with safer settings."
        }
    }
}


public struct GeodesicAppearance: Equatable, Sendable {
    public var particleDiameterPoints: Double = 12
    public var trailWidthPoints: Double = 1.2
    public var particleVisible = true
    public var trailVisible = true
    public init() {}
    public var isValid: Bool {
        particleDiameterPoints.isFinite && (4...28).contains(particleDiameterPoints) &&
        trailWidthPoints.isFinite && (0.5...3).contains(trailWidthPoints)
    }
}
