import Foundation
import simd

/// Equatorial spatial Ellis geometry, not a spacetime or optical model.
public struct LegacyFunnelProfile: Equatable, Sendable {
    public var depth: Double = 7
    public var referenceRadius: Double = 10
    public var fieldHalfExtent: Double = 36
    public var showsOtherRegion = false
    public var roundedReturnEdge = false
    public init() {}
    /// Display lifecycle only: the finite grid is not a reflecting boundary.
    public func shouldDisappear(at position: SIMD3<Double>) -> Bool {
        max(abs(position.x),abs(position.z)) > fieldHalfExtent+4
    }
}

public struct EllisWormhole: Equatable, Sendable {
    public var throatRadius: Double = 2
    public var extent: Double = 12
    public var funnel: LegacyFunnelProfile? = nil
    public init(throatRadius: Double = 2, extent: Double = 12) {
        self.throatRadius = throatRadius; self.extent = extent
    }
    public var isValid: Bool {
        guard throatRadius.isFinite, (1...4).contains(throatRadius), extent.isFinite, (12...80).contains(extent) else { return false }
        if let funnel {
            return funnel.depth.isFinite && (2...12).contains(funnel.depth) && funnel.referenceRadius.isFinite &&
                funnel.referenceRadius > throatRadius && funnel.fieldHalfExtent.isFinite && (16...36).contains(funnel.fieldHalfExtent) &&
                extent >= funnel.fieldHalfExtent*sqrt(2)
        }
        return true
    }
    public var camera: OrbitCamera {
        guard let funnel else { return OrbitCamera(yaw: 0.4,pitch: 0.28,distance: 44) }
        var camera = OrbitCamera(yaw: 0.35,pitch: 0.78,distance: 105)
        camera.target.y = funnel.showsOtherRegion ? -funnel.depth : -2
        return camera
    }
    public var axialScale: Double { funnel.map { $0.depth/acosh($0.referenceRadius/throatRadius) } ?? throatRadius }
    public func radius(l: Double) -> Double { hypot(l,throatRadius) }
    public func metric(l: Double) -> SIMD2<Double> {
        let g = l*l+throatRadius*throatRadius
        return SIMD2(funnel == nil ? 1 : (l*l+axialScale*axialScale)/g,g)
    }
    // Standard embedding (x,y,z), with z the symmetry axis.
    public func position(l: Double, phi: Double) -> SIMD3<Double> {
        let r = radius(l: l)
        return SIMD3(r*cos(phi),r*sin(phi),axialScale*asinh(l/throatRadius)-(funnel?.depth ?? 0))
    }
    public func displayPosition(l: Double, phi: Double) -> SIMD3<Double> {
        let p = position(l: l,phi: phi); return SIMD3(p.x,p.z,p.y)
    }
    public func normal(l: Double, phi: Double) -> SIMD3<Double> {
        SIMD3(axialScale*cos(phi),-l,axialScale*sin(phi))/hypot(l,axialScale)
    }
    // State = (l,phi,dl/ds,dphi/ds). ds is affine unit-speed spatial distance.
    public func derivative(_ state: SIMD4<Double>) -> SIMD4<Double> {
        let g = metric(l: state.x).y
        if funnel == nil { return SIMD4(state.z,state.w,state.x*state.w*state.w,-2*state.x*state.z*state.w/g) }
        let b = axialScale, h = state.x*state.x+b*b
        let radial = state.x*(b*b-throatRadius*throatRadius)/(g*h)*state.z*state.z + state.x*g/h*state.w*state.w
        return SIMD4(state.z,state.w,radial,-2*state.x*state.z*state.w/g)
    }
    public func energy(_ state: SIMD4<Double>) -> Double { metric(l: state.x).x*state.z*state.z+metric(l: state.x).y*state.w*state.w }
    public func momentum(_ state: SIMD4<Double>) -> Double { metric(l: state.x).y*state.w }
}

public enum WormholeLaunch: String, CaseIterable, Identifiable, Sendable {
    case crossing, deflection, nearCritical
    public var id: String { rawValue }
    public var title: String {
        switch self { case .crossing: "Crossing"; case .deflection: "Deflection"; case .nearCritical: "Near-critical" }
    }
    public var impactRatio: Double {
        switch self { case .crossing: 0.65; case .deflection: 1.4; case .nearCritical: 1.0001 }
    }
    public var summary: String {
        switch self {
        case .crossing: "Pass through the throat into the other region."
        case .deflection: "Approach, turn before the throat and return to the original region."
        case .nearCritical: "Wind near the throat before returning; J/a is slightly above one."
        }
    }
}

public struct WormholeConfiguration: Equatable, Sendable {
    public var geometry = EllisWormhole()
    public var initialL: Double = 8
    public var initialPhi: Double = .pi/6
    public var impactRatio: Double = WormholeLaunch.crossing.impactRatio
    public var initiallyInward = true
    public init() {}
    public init(example: WormholeLaunch) { impactRatio = example.impactRatio }
    public var angularMomentum: Double { impactRatio*geometry.throatRadius }
    public var isValid: Bool {
        geometry.isValid && initialL.isFinite && (-80...80).contains(initialL) &&
        initialPhi.isFinite && (0...2*Double.pi).contains(initialPhi) &&
        impactRatio.isFinite && (-80...80).contains(impactRatio) &&
        abs(angularMomentum) <= geometry.radius(l: initialL)
    }
    public var validationMessage: String {
        "Use a = 1–4, initial l = −80…80, φ = 0–360° and |J| ≤ the launch radius. Unit speed also requires |J/a| ≤ √(1 + (l₀/a)²); reduce |J/a| or start farther from the throat."
    }
    public var initialState: SIMD4<Double> {
        let g = geometry.metric(l: initialL).y
        let radialSquare = 1-angularMomentum*angularMomentum/g
        // isValid excludes negative radial energy. max handles only roundoff at the
        // admissible equality (an initial turning point), never clamps invalid inputs.
        let direction = (initialL < 0 ? 1.0 : -1.0)*(initiallyInward ? 1 : -1)
        let radial = direction*sqrt(max(0,radialSquare)/geometry.metric(l: initialL).x)
        return SIMD4(initialL,TorusMetric.wrap(initialPhi),radial,angularMomentum/g)
    }
}

public struct WormholeSolver: Sendable {
    public let configuration: WormholeConfiguration
    public private(set) var state: SIMD4<Double>
    public private(set) var steps: UInt64 = 0
    public init(configuration: WormholeConfiguration) throws {
        guard configuration.isValid, configuration.geometry.funnel?.roundedReturnEdge != true else { throw WormholeError.invalidConfiguration(configuration.validationMessage) }
        self.configuration = configuration; state = configuration.initialState
    }
    public var position: SIMD3<Double> { configuration.geometry.displayPosition(l: state.x,phi: state.y) }
    public var energyDrift: Double { configuration.geometry.energy(state)-1 }
    public var momentumDrift: Double { configuration.geometry.momentum(state)-configuration.angularMomentum }
    public mutating func restart() { state = configuration.initialState; steps = 0 }
    public mutating func advance(steps count: Int,dt: Double = FixedStepClock.timestep) throws {
        guard (0...1_000_000).contains(count), dt.isFinite, dt > 0, dt <= 0.1 else { throw WormholeError.invalidStep }
        let geometry = configuration.geometry
        for _ in 0..<count {
            let a = geometry.derivative(state), b = geometry.derivative(state+a*(dt/2))
            let c = geometry.derivative(state+b*(dt/2)), d = geometry.derivative(state+c*dt)
            let weighted: SIMD4<Double> = (a+b*2)+(c*2+d)
            var next = state+weighted*(dt/6)
            next.y = TorusMetric.wrap(next.y)
            guard (0..<4).allSatisfy({ next[$0].isFinite }), abs(next.x) < 1e6,
                  abs(geometry.energy(next)-1) < 0.01 else { throw WormholeError.unstableIntegration }
            state = next; steps += 1
        }
    }
}

public struct WormholePlayback: Sendable {
    public private(set) var solver: WormholeSolver
    public private(set) var trail: GeodesicTrail
    public private(set) var clock = FixedStepClock()
    public private(set) var hasExited = false
    public private(set) var hasDisappeared = false
    public var isPaused = false
    public var playbackRate = 2.0
    public var presentationFraction: Double?
    private var previousState: SIMD4<Double>
    public init(configuration: WormholeConfiguration,trailLength: Int = 8192) throws {
        solver = try WormholeSolver(configuration: configuration)
        trail = try GeodesicTrail(capacity: trailLength); trail.append(solver.position)
        previousState = solver.state
    }
    public var presentationPosition: SIMD3<Double> {
        if isPaused { return solver.position }
        let fraction = min(1,max(0,presentationFraction ?? clock.remainder/FixedStepClock.timestep))
        let l = previousState.x+(solver.state.x-previousState.x)*fraction
        let phi = previousState.y+TorusMetric.wrap(solver.state.y-previousState.y)*fraction
        return solver.configuration.geometry.displayPosition(l: l,phi: phi)
    }
    public mutating func restart() {
        solver.restart(); trail.reset(to: solver.position); clock.reset(); hasExited = false; hasDisappeared = false
        previousState = solver.state
    }
    public mutating func advance(elapsed: Double) throws {
        guard playbackRate.isFinite, (0.125...16).contains(playbackRate) else { throw WormholeError.invalidStep }
        try integrate(clock.consume(elapsed: elapsed,speed: playbackRate,paused: isPaused,maximumSpeed: 16))
    }
    public mutating func singleStep() throws { if isPaused { try integrate(1) } }
    private mutating func integrate(_ count: Int) throws {
        for _ in 0..<count {
            guard !hasDisappeared else { break }
            previousState = solver.state
            try solver.advance(steps: 1); trail.append(solver.position)
            hasDisappeared = solver.configuration.geometry.funnel?.shouldDisappear(at: solver.position) ?? false
            if abs(solver.state.x) >= solver.configuration.geometry.extent {
                hasExited = true // Informational only: the mesh is not a physical boundary.
            }
        }
    }
}

public enum WormholePresentation: String, CaseIterable, Identifiable, Sendable {
    case surface, wireframe, trajectories
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
}
public struct WormholeSurfaceAppearance: Equatable, Sendable {
    public var mode: WormholePresentation = .surface
    public var opacity: Double = 0.85
    public var meshVisible = true
    public var throatVisible = true
    public init() {}
    public var isValid: Bool { opacity.isFinite && (0...1).contains(opacity) }
}
public enum WormholeError: LocalizedError {
    case invalidConfiguration(String), invalidStep, unstableIntegration
    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(message): message
        case .invalidStep: "Invalid wormhole timestep, step count or playback rate."
        case .unstableIntegration: "Spatial geodesic integration exceeded finite-state or 1% energy-drift limits. Restart with safer initial conditions."
        }
    }
}
