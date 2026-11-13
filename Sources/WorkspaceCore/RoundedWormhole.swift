import Foundation
import simd

/// Two funnel sheets joined along x = fieldHalfExtent. The other three edges
/// remain open. F = (y + depth)^2 - heightSquared(x,z) defines the surface.
public struct RoundedWormhole: Sendable {
    public let geometry: EllisWormhole
    public init(geometry: EllisWormhole) { self.geometry = geometry }
    public var edge: Double { geometry.funnel?.fieldHalfExtent ?? 36 }
    public var depth: Double { geometry.funnel?.depth ?? 7 }
    public var width: Double { min(edge*0.65,geometry.axialScale*acosh(edge/geometry.throatRadius)) }

    // acosh(r/a)^2 has a regular continuation through r=a. The series avoids
    // cancellation in its first two derivatives at the throat during RK4 stages.
    private func radial(_ radius: Double) -> SIMD3<Double> {
        let a = geometry.throatRadius, b2 = geometry.axialScale*geometry.axialScale
        let t = radius/a-1
        if abs(t) < 0.001 {
            let g = 2*t-t*t/3+4*t*t*t/45-t*t*t*t/35
            let first = 2-2*t/3+4*t*t/15-4*t*t*t/35
            let second = -2.0/3+8*t/15-12*t*t/35
            return SIMD3(g*b2,first*b2/a,second*b2/(a*a))
        }
        if radius > a {
            let c = acosh(radius/a), s = sqrt(radius*radius-a*a)
            return SIMD3(b2*c*c,2*b2*c/s,2*b2*(1/(s*s)-radius*c/(s*s*s)))
        }
        let c = acos(radius/a), s = sqrt(a*a-radius*radius)
        return SIMD3(-b2*c*c,2*b2*c/s,2*b2*(-1/(s*s)+radius*c/(s*s*s)))
    }
    private func cap(_ x: Double) -> SIMD3<Double> {
        let q = (x-(edge-width))/width
        if q <= 0 { return SIMD3(1,0,0) }
        // Elliptical return, with a C4 blend into the unchanged funnel sheet.
        // Beyond the blend: (height/originalHeight)^2 + q^2 = 1.
        let blend = 0.2
        if q >= blend { return SIMD3(1-q*q,-2*q/width,-2/(width*width)) }
        let t = q/blend
        let smooth = pow(t,5)*(126+t*(-420+t*(540+t*(-315+70*t))))
        let first = 630*pow(t,4)*pow(1-t,4)/blend
        let second = 2520*pow(t,3)*pow(1-t,3)*(1-2*t)/(blend*blend)
        return SIMD3(1-q*q*smooth,-(2*q*smooth+q*q*first)/width,
                     -(2*smooth+4*q*first+q*q*second)/(width*width))
    }
    /// A finite grid coordinate at the return tangent. Store at vertices rather
    /// than applying ill-conditioned asin to interpolated Float world positions.
    public func gridAngle(x: Double) -> Double {
        let q = max(0,min(1,(x-(edge-width))/width))
        return atan2(q,sqrt(max(0,cap(x).x)))
    }
    public func heightSquared(x: Double,z: Double) -> Double {
        radial(hypot(x,z)).x*cap(x).x
    }
    public func position(x: Double,z: Double,upper: Bool) -> SIMD3<Double> {
        SIMD3(x,-depth+(upper ? 1 : -1)*sqrt(max(0,heightSquared(x: x,z: z))),z)
    }
    public func differential(at p: SIMD3<Double>) -> (value: Double,gradient: SIMD3<Double>,hessian: simd_double3x3) {
        let r = max(1e-8,hypot(p.x,p.z)), g = radial(r), h = cap(p.x)
        let nx = p.x/r, nz = p.z/r
        let gx = g.y*nx, gz = g.y*nz
        let gxx = g.z*nx*nx+g.y/r*(1-nx*nx)
        let gzz = g.z*nz*nz+g.y/r*(1-nz*nz)
        let gxz = (g.z-g.y/r)*nx*nz
        let gradient = SIMD3(-(gx*h.x+g.x*h.y),2*(p.y+depth),-gz*h.x)
        let xx = -(gxx*h.x+2*gx*h.y+g.x*h.z)
        let xz = -(gxz*h.x+gz*h.y), zz = -gzz*h.x
        let hessian = simd_double3x3(rows: [SIMD3(xx,0,xz),SIMD3(0,2,0),SIMD3(xz,0,zz)])
        return ((p.y+depth)*(p.y+depth)-g.x*h.x,gradient,hessian)
    }
    public func normal(at p: SIMD3<Double>) -> SIMD3<Double> { simd_normalize(differential(at: p).gradient) }
    public func acceleration(position: SIMD3<Double>,velocity: SIMD3<Double>) -> SIMD3<Double> {
        let d = differential(at: position)
        // Intrinsic geodesic acceleration is purely normal to an implicit surface.
        return -simd_dot(velocity,d.hessian*velocity)/simd_length_squared(d.gradient)*d.gradient
    }
}

public struct RoundedWormholeSolver: Sendable {
    public let surface: RoundedWormhole
    public private(set) var position: SIMD3<Double>
    public private(set) var velocity: SIMD3<Double>
    public private(set) var steps: UInt64 = 0
    public init(beam: WormholeBeam,index: Int) throws {
        guard beam.isValid, beam.starts.indices.contains(index) else { throw WormholeError.invalidConfiguration("Invalid starting positions.") }
        surface = RoundedWormhole(geometry: beam.geometry)
        let start = beam.starts[index]
        guard start.x < surface.edge-0.25 else { throw WormholeError.invalidConfiguration("Place starts before the rounded +X edge.") }
        position = surface.position(x: start.x,z: start.y,upper: true)
        let d = surface.differential(at: position)
        guard d.gradient.y > 1e-8 else { throw WormholeError.invalidConfiguration("Place starts on the upper sheet, outside the throat and return edge.") }
        let vx = cos(beam.heading), vz = sin(beam.heading)
        let vy = -(d.gradient.x*vx+d.gradient.z*vz)/d.gradient.y
        velocity = simd_normalize(SIMD3(vx,vy,vz))
    }
    public var energyDrift: Double { simd_length_squared(velocity)-1 }
    public var surfaceError: Double {
        let d = surface.differential(at: position)
        return abs(d.value)/simd_length(d.gradient)
    }
    public var tangentError: Double { abs(simd_dot(surface.normal(at: position),velocity)) }
    public mutating func advance(dt: Double = FixedStepClock.timestep) throws {
        guard dt.isFinite, dt > 0, dt <= 0.1 else { throw WormholeError.invalidStep }
        let p = position, v = velocity
        let a = surface.acceleration(position: p,velocity: v)
        let vb = v+a*(dt/2), pb = p+v*(dt/2)
        let b = surface.acceleration(position: pb,velocity: vb)
        let vc = v+b*(dt/2), pc = p+vb*(dt/2)
        let c = surface.acceleration(position: pc,velocity: vc)
        let vd = v+c*dt, pd = p+vc*dt
        let d = surface.acceleration(position: pd,velocity: vd)
        let positionSum: SIMD3<Double> = (v+vb*2)+(vc*2+vd)
        let velocitySum: SIMD3<Double> = (a+b*2)+(c*2+d)
        position += positionSum*(dt/6)
        velocity += velocitySum*(dt/6)
        guard (0..<3).allSatisfy({ position[$0].isFinite && velocity[$0].isFinite }),
              simd_length(position) < 1e6, abs(energyDrift) < 0.01, surfaceError < 0.01, tangentError < 0.01 else {
            throw WormholeError.unstableIntegration
        }
        steps += 1
    }
}

public struct RoundedWormholeTrack: Sendable {
    public private(set) var solver: RoundedWormholeSolver
    public private(set) var trail: GeodesicTrail
    public private(set) var clock = FixedStepClock()
    public var isPaused = false
    public private(set) var hasDisappeared = false
    public var presentationFraction: Double?
    private var previousPosition: SIMD3<Double>
    public init(beam: WormholeBeam,index: Int,trailLength: Int) throws {
        solver = try RoundedWormholeSolver(beam: beam,index: index)
        previousPosition = solver.position
        trail = try GeodesicTrail(capacity: trailLength); trail.append(solver.position)
    }
    public var presentationPosition: SIMD3<Double> {
        if isPaused { return solver.position }
        let fraction = min(1,max(0,presentationFraction ?? clock.remainder/FixedStepClock.timestep))
        // Put the interpolated display point back on the analytic sheet. This
        // small Newton correction never changes the solver state or its velocity.
        var point = previousPosition+(solver.position-previousPosition)*fraction
        for _ in 0..<2 {
            let d = solver.surface.differential(at: point)
            point -= d.gradient*(d.value/simd_length_squared(d.gradient))
        }
        return point
    }
    public mutating func advance(elapsed: Double,paused: Bool,rate: Double) throws {
        guard rate.isFinite, (0.125...16).contains(rate) else { throw WormholeError.invalidStep }
        isPaused = paused
        try integrate(clock.consume(elapsed: elapsed,speed: rate,paused: paused,maximumSpeed: 16))
    }
    public mutating func step() throws { isPaused = true; try integrate(1) }
    private mutating func integrate(_ count: Int) throws {
        for _ in 0..<count {
            guard !hasDisappeared else { break }
            previousPosition = solver.position; try solver.advance(); trail.append(solver.position)
            hasDisappeared = solver.surface.geometry.funnel?.shouldDisappear(at: solver.position) ?? false
        }
    }
}

public struct RoundedWormholeComparison: Sendable {
    public private(set) var tracks: [RoundedWormholeTrack]
    public private(set) var stream: WormholeLaunchStream
    private let beam: WormholeBeam
    private let trailLength: Int
    private let launches: WormholeLaunchSettings
    private var clock = FixedStepClock()
    public init(beam: WormholeBeam,trailLength: Int,launches: WormholeLaunchSettings = WormholeLaunchSettings()) throws {
        guard beam.isValid, launches.isValid else { throw WormholeError.invalidConfiguration("Invalid launch variation.") }
        self.beam = beam; self.trailLength = trailLength; self.launches = launches
        stream = WormholeLaunchStream(count: beam.starts.count,continuous: launches.continuous,startTogether: launches.startTogether)
        tracks = try beam.starts.indices.map { try RoundedWormholeTrack(beam: beam,index: $0,trailLength: trailLength) }
    }
    public func isVisible(_ index: Int) -> Bool { stream.active[index] && !tracks[index].hasDisappeared }
    public mutating func advance(elapsed: Double,paused: Bool,rate: Double) throws {
        if launches.continuous {
            guard rate.isFinite, (0.125...16).contains(rate) else { throw WormholeError.invalidStep }
            try integrate(clock.consume(elapsed: elapsed,speed: rate,paused: paused,maximumSpeed: 16))
            for i in tracks.indices {
                tracks[i].isPaused = paused
                tracks[i].presentationFraction = clock.remainder/FixedStepClock.timestep
            }
        } else {
            for i in tracks.indices { try tracks[i].advance(elapsed: elapsed,paused: paused,rate: rate) }
        }
    }
    private mutating func integrate(_ count: Int) throws {
        for _ in 0..<count {
            if let index = stream.advance(retired: tracks.map(\.hasDisappeared)) {
                let varied = launches.beam(beam,index: index,generation: stream.generations[index])
                tracks[index] = try RoundedWormholeTrack(beam: varied,index: index,trailLength: trailLength)
            }
            for index in tracks.indices where stream.active[index] { try tracks[index].step() }
        }
    }
    public mutating func step() throws {
        if launches.continuous { try integrate(1) }
        else { for i in tracks.indices { try tracks[i].step() } }
    }
}
