import Foundation
import simd

/// Parallel planar headings are lifted to each starting tangent plane and normalized
/// with the induced metric. Starting position, not steering, changes the outcome.
public struct WormholeBeam: Equatable, Sendable {
    public var geometry: EllisWormhole
    public var starts: [SIMD2<Double>]
    public var heading: Double = 0
    public init() {
        var geometry = EllisWormhole(throatRadius: 1.6,extent: 52)
        geometry.funnel = LegacyFunnelProfile(); self.geometry = geometry
        starts = (0..<13).map { SIMD2(-18,Double($0-6)*0.8) }
    }
    public var isValid: Bool {
        geometry.isValid && (1...17).contains(starts.count) && heading.isFinite && abs(heading) <= .pi &&
        starts.allSatisfy { $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 32 && abs($0.y) <= 32 && simd_length($0) > geometry.throatRadius+0.25 }
    }
    public func launch(_ index: Int) throws -> WormholeConfiguration {
        guard isValid, starts.indices.contains(index) else { throw WormholeError.invalidConfiguration("Place 1–17 balls outside the throat (within ±32), with a finite common heading.") }
        let p = starts[index], radius = simd_length(p), a = geometry.throatRadius
        let l = sqrt(radius*radius-a*a), phi = atan2(p.y,p.x)
        let radial = cos(heading-phi), tangential = sin(heading-phi)
        let ldot = radial*radius/l
        let speed = sqrt(geometry.metric(l: l).x*ldot*ldot+tangential*tangential)
        var result = WormholeConfiguration()
        result.geometry = geometry; result.initialL = l
        result.initialPhi = phi < 0 ? phi+2 * .pi : phi
        result.impactRatio = radius*tangential/(speed*a)
        result.initiallyInward = radial <= 0
        return result
    }
    public mutating func arrange(count: Int,startX: Double,center: Double,width: Double) throws {
        guard (1...17).contains(count), startX.isFinite, center.isFinite, width.isFinite, (0...24).contains(width) else { throw WormholeError.invalidStep }
        let proposed = (0..<count).map { SIMD2(startX,center+(count == 1 ? 0 : (Double($0)/Double(count-1)-0.5)*width)) }
        var draft = self; draft.starts = proposed
        guard draft.isValid else { throw WormholeError.invalidConfiguration("Starting row must stay outside the throat and within ±32.") }
        self = draft
    }
}

/// Randomness affects launch conditions only; every trajectory remains a geodesic.
public struct WormholeLaunchSettings: Equatable, Sendable {
    public var continuous = false
    public var startTogether = true
    public var variation = 0.5
    public var seed: UInt64 = 42
    public init() {}
    public var isValid: Bool { variation.isFinite && (0...1).contains(variation) }
    func beam(_ original: WormholeBeam,index: Int,generation: UInt64) -> WormholeBeam {
        func signed(_ salt: UInt64) -> Double {
            var value = seed &+ UInt64(index) &* 0x9E3779B97F4A7C15 &+ generation &* 0xBF58476D1CE4E5B9 &+ salt
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            value ^= value >> 31
            return Double(value >> 11)/9007199254740992*2-1
        }
        var result = original
        result.starts[index] += SIMD2(signed(1),signed(2))*(variation*0.6)
        result.heading = max(-.pi,min(.pi,original.heading+signed(3)*variation*0.04))
        // A valid user start near the throat must not become invalid through jitter.
        if original.geometry.funnel?.roundedReturnEdge == true,
           result.starts[index].x >= original.geometry.funnel!.fieldHalfExtent-0.25 { return original }
        return result.isValid ? result : original
    }
}

/// A bounded pool: launch one waiting slot every two simulation units. Only
/// escaped slots are reused; particles still on the surface are never replaced.
public struct WormholeLaunchStream: Sendable {
    public private(set) var active: [Bool]
    public private(set) var generations: [UInt64]
    private var readyAt: [UInt64]
    private var tick: UInt64 = 0
    private var nextLaunch: UInt64 = 1
    private var cursor = 0
    private let interval = UInt64((2/FixedStepClock.timestep).rounded())
    init(count: Int,continuous: Bool,startTogether: Bool = false) {
        active = Array(repeating: !continuous || startTogether,count: count)
        generations = Array(repeating: continuous && startTogether ? 1 : 0,count: count)
        readyAt = Array(repeating: 0,count: count)
    }
    mutating func advance(retired: [Bool]) -> Int? {
        tick += 1
        for index in active.indices where active[index] && retired[index] {
            active[index] = false; readyAt[index] = tick+interval
        }
        guard tick >= nextLaunch else { return nil }
        for offset in 0..<active.count {
            let index = (cursor+offset)%active.count
            if !active[index] && readyAt[index] <= tick {
                active[index] = true; generations[index] += 1
                nextLaunch = tick+interval; cursor = (index+1)%active.count
                return index
            }
        }
        return nil
    }
}

public struct WormholeComparison: Sendable {
    public private(set) var tracks: [WormholePlayback]
    public private(set) var stream: WormholeLaunchStream
    private let beam: WormholeBeam
    private let trailLength: Int
    private let launches: WormholeLaunchSettings
    private var clock = FixedStepClock()
    public init(beam: WormholeBeam,trailLength: Int = 8192,launches: WormholeLaunchSettings = WormholeLaunchSettings()) throws {
        guard beam.isValid, launches.isValid else { throw WormholeError.invalidConfiguration("Invalid funnel, starting positions or launch variation.") }
        self.beam = beam; self.trailLength = trailLength; self.launches = launches
        stream = WormholeLaunchStream(count: beam.starts.count,continuous: launches.continuous,startTogether: launches.startTogether)
        tracks = try beam.starts.indices.map { try WormholePlayback(configuration: beam.launch($0),trailLength: trailLength) }
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
            return
        }
        for i in tracks.indices {
            tracks[i].isPaused = paused; tracks[i].playbackRate = rate
            try tracks[i].advance(elapsed: elapsed)
        }
    }
    private mutating func integrate(_ count: Int) throws {
        for _ in 0..<count {
            if let index = stream.advance(retired: tracks.map(\.hasDisappeared)) {
                let varied = launches.beam(beam,index: index,generation: stream.generations[index])
                tracks[index] = try WormholePlayback(configuration: varied.launch(index),trailLength: trailLength)
            }
            for index in tracks.indices where stream.active[index] {
                tracks[index].isPaused = true; try tracks[index].singleStep()
            }
        }
    }
    public mutating func singleStep(paused: Bool) throws {
        guard paused else { return }
        if launches.continuous { try integrate(1) }
        else { for i in tracks.indices { tracks[i].isPaused = true; try tracks[i].singleStep() } }
    }
    public mutating func restart(paused: Bool) throws {
        // Rebuild from the original row, not a recycled slot's varied launch.
        tracks = try beam.starts.indices.map { try WormholePlayback(configuration: beam.launch($0),trailLength: trailLength) }
        for i in tracks.indices { tracks[i].isPaused = paused }
        clock.reset(); stream = WormholeLaunchStream(count: tracks.count,continuous: launches.continuous,startTogether: launches.startTogether)
    }
    public func outcome(_ index: Int) -> String {
        let track = tracks[index]
        if track.solver.state.x < 0 { return "Through throat" }
        if track.solver.state.z > 0 { return track.solver.configuration.initiallyInward ? "Deflected outward" : "Outbound" }
        return "Approaching"
    }
}

public struct GeodesicRenderTrack: Sendable {
    public var trail: GeodesicTrail
    public var particle: SIMD3<Double>?
    public var color: SIMD4<Float>
    public var appearance: GeodesicAppearance
    public var ballNormal: SIMD3<Double>?
    public init(trail: GeodesicTrail,particle: SIMD3<Double>?,color: SIMD4<Float> = SIMD4(0.88,0.55,0.20,1),appearance: GeodesicAppearance = GeodesicAppearance(),ballNormal: SIMD3<Double>? = nil) {
        self.trail = trail; self.particle = particle; self.color = color; self.appearance = appearance; self.ballNormal = ballNormal
    }
}
