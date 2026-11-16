import Foundation

public struct LorenzParameters: Equatable, Sendable {
    public var sigma: Double = 10
    public var rho: Double = 28
    public var beta: Double = 8 / 3
    public init(sigma: Double = 10, rho: Double = 28, beta: Double = 8 / 3) {
        self.sigma = sigma; self.rho = rho; self.beta = beta
    }
    public var isValid: Bool {
        sigma.isFinite && rho.isFinite && beta.isFinite &&
        (1...30).contains(sigma) && (0...60).contains(rho) && (0.1...10).contains(beta)
    }
}

public struct LorenzConfiguration: Equatable, Sendable {
    public static let timestep = FixedStepClock.timestep
    public static let warmupSteps = 2400
    public var parameters = LorenzParameters()
    public var trajectoryCount = 12
    public var trailLength = 2048
    public var seed: UInt32 = 0x4C4F5245
    public init() {}
    public var isValid: Bool {
        parameters.isValid && (1...128).contains(trajectoryCount) && (256...8192).contains(trailLength)
    }
    public var historyBytes: Int { trajectoryCount * trailLength * 16 }
}

public enum LorenzMath {
    public static func derivative(_ p: SIMD3<Double>, parameters m: LorenzParameters) -> SIMD3<Double> {
        SIMD3(m.sigma * (p.y - p.x), p.x * (m.rho - p.z) - p.y, p.x * p.y - m.beta * p.z)
    }
    public static func rk4(_ p: SIMD3<Double>, parameters m: LorenzParameters, dt: Double = LorenzConfiguration.timestep) -> SIMD3<Double> {
        let a = derivative(p, parameters: m)
        let b = derivative(p + a * (dt / 2), parameters: m)
        let c = derivative(p + b * (dt / 2), parameters: m)
        let d = derivative(p + c * dt, parameters: m)
        return p + (a + 2 * b + 2 * c + d) * (dt / 6)
    }
    public static func isSafe(_ p: SIMD3<Double>) -> Bool {
        p.x.isFinite && p.y.isFinite && p.z.isFinite && max(abs(p.x), abs(p.y), abs(p.z)) < 10000
    }
    public static func initialPoint(index: UInt32, seed: UInt32) -> SIMD3<Float> {
        func component(_ lane: UInt32) -> Float {
            var x = seed &+ index &* 747796405 &+ lane &* 2891336453
            x = (x ^ (x >> 16)) &* 2246822519
            x = (x ^ (x >> 13)) &* 3266489917
            x ^= x >> 16
            return 1 + (Float(x & 0x00FFFFFF) / 16777216 - 0.5) * 0.04
        }
        return SIMD3(component(0), component(1), component(2))
    }
}

public struct LorenzReference {
    public private(set) var point: SIMD3<Double>
    public private(set) var steps: UInt64 = 0
    public private(set) var restarts = 0
    private let initial: SIMD3<Double>
    public init(index: UInt32 = 0, seed: UInt32 = 0x4C4F5245) {
        initial = SIMD3<Double>(LorenzMath.initialPoint(index: index, seed: seed))
        point = initial
    }
    public mutating func reset() { point = initial; steps = 0; restarts = 0 }
    public mutating func advance(steps count: Int, parameters: LorenzParameters) throws {
        guard parameters.isValid, count >= 0 else { throw LorenzError.invalidConfiguration }
        for _ in 0..<count {
            let next = LorenzMath.rk4(point, parameters: parameters)
            if LorenzMath.isSafe(next) { point = next }
            else { point = initial; restarts += 1 }
            steps += 1
        }
    }
}

public enum LorenzError: LocalizedError {
    case invalidConfiguration
    case metalUnavailable
    case resourceFailure
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "Invalid Lorenz configuration."
        case .metalUnavailable: "Metal is unavailable in this session."
        case .resourceFailure: "Metal could not allocate or encode the Lorenz scene."
        }
    }
}

public struct FixedStepClock: Sendable {
    public static let timestep = 1.0 / 240
    public private(set) var remainder = 0.0
    public private(set) var discardedTime = 0.0
    public private(set) var steps: UInt64 = 0
    public init() {}
    public mutating func reset() { self = Self() }
    public mutating func consume(elapsed: Double, speed: Double = 1, paused: Bool = false, maximumSpeed: Double = 4, timestep: Double = Self.timestep) -> Int {
        guard !paused, elapsed.isFinite, elapsed >= 0, speed.isFinite, maximumSpeed.isFinite, (4...16).contains(maximumSpeed), (0.125...maximumSpeed).contains(speed) else { return 0 }
        guard timestep.isFinite, (1e-6...0.1).contains(timestep) else { return 0 }
        let dt = timestep
        let added = min(elapsed, 0.25) * speed
        discardedTime += max(0, elapsed - 0.25) * speed
        remainder += added
        let due = Int(floor((remainder + dt * 1e-9) / dt))
        let count = min(due, 64)
        remainder = max(0, remainder - Double(due) * dt)
        discardedTime += Double(due - count) * dt
        steps += UInt64(count)
        return count
    }
}

public struct OrbitCamera: Equatable, Sendable {
    public var yaw: Double = 0.35
    public var pitch: Double = 0.15
    public var distance: Double = 105
    public var pan = SIMD2<Double>.zero
    public var target = SIMD3<Double>.zero
    public init(yaw: Double = 0.35, pitch: Double = 0.15, distance: Double = 105) {
        self.yaw = yaw; self.pitch = pitch; self.distance = distance
    }
    public mutating func orbit(x: Double, y: Double) {
        guard x.isFinite, y.isFinite else { return }
        yaw = (yaw + x * 0.006).truncatingRemainder(dividingBy: .pi * 2)
        pitch = min(1.35, max(-1.35, pitch + y * 0.006))
    }
    public mutating func zoom(_ amount: Double, minimumDistance: Double = 35) {
        guard amount.isFinite, minimumDistance.isFinite, (1...35).contains(minimumDistance) else { return }
        distance = min(250, max(minimumDistance, distance * exp(min(5, max(-5, amount)))))
    }
    public mutating func translate(x: Double, y: Double, viewportHeight: Double) {
        guard x.isFinite, y.isFinite, viewportHeight.isFinite, viewportHeight > 0 else { return }
        let scale = distance * 0.7 / viewportHeight
        pan += SIMD2(x * scale, -y * scale)
        pan = SIMD2(min(100, max(-100, pan.x)), min(100, max(-100, pan.y)))
    }
}

public enum LorenzRepresentation: String, Sendable { case line, ribbon }

public struct LorenzAppearance: Equatable, Sendable {
    public var widthPixels: Float
    public var opacity: Float
    public var low: SIMD4<Float>
    public var high: SIMD4<Float>
    public var representation: LorenzRepresentation = .line
    public var ribbonWidth: Double = 0.32
    public var fade = TrailFade()
    public var isValid: Bool {
        widthPixels.isFinite && (0.25...3).contains(widthPixels) && opacity.isFinite && (0...1).contains(opacity) &&
        ribbonWidth.isFinite && (0.04...1.2).contains(ribbonWidth) && fade.isValid &&
        (0..<4).allSatisfy { low[$0].isFinite && high[$0].isFinite && (0...1).contains(low[$0]) && (0...1).contains(high[$0]) }
    }
}

public enum LorenzPreset: String, CaseIterable, Identifiable, Sendable {
    case classic, filament, sculpture
    public var id: String { rawValue }
    public var title: String { rawValue.capitalized }
    public var summary: String {
        switch self {
        case .classic: "Classic traces the butterfly-shaped flow with clear, cool lines. Follow a single path as it loops around one lobe, then crosses to the other."
        case .filament: "Filament layers many fine, translucent threads. Nearby paths slowly separate, weaving a dense pattern that reveals sensitivity to starting conditions."
        case .sculpture: "Sculpture turns the paths into narrow bronze ribbons. Their surfaces twist through space and catch the light; orbit the camera to see the folds and depth."
        }
    }
    public var configuration: LorenzConfiguration {
        var value = LorenzConfiguration()
        switch self {
        case .classic: break
        case .filament: value.trajectoryCount = 24; value.trailLength = 3072
        case .sculpture: value.trajectoryCount = 6; value.trailLength = 4096
        }
        return value
    }
    public var camera: OrbitCamera {
        OrbitCamera()
    }
    public var appearance: LorenzAppearance {
        switch self {
        case .classic: LorenzAppearance(widthPixels: 0.85, opacity: 0.44, low: SIMD4(0.10, 0.21, 0.32, 1), high: SIMD4(0.72, 0.82, 0.88, 1))
        case .filament: LorenzAppearance(widthPixels: 0.55, opacity: 0.25, low: SIMD4(0.08, 0.23, 0.22, 1), high: SIMD4(0.65, 0.76, 0.57, 1), fade: TrailFade(delay: 1, duration: 9))
        case .sculpture: LorenzAppearance(widthPixels: 1.25, opacity: 0.88, low: SIMD4(0.22, 0.075, 0.025, 1), high: SIMD4(0.68, 0.36, 0.12, 1), representation: .ribbon, fade: TrailFade(delay: 3, duration: 9))
        }
    }
}
