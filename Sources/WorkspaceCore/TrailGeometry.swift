import Foundation
import simd

public struct TrailFade: Equatable, Sendable {
    public var delay: Double
    public var duration: Double
    public init(delay: Double = 2, duration: Double = 5) { self.delay = delay; self.duration = duration }
    public var isValid: Bool { delay.isFinite && duration.isFinite && (0...30).contains(delay) && (0...30).contains(duration) }

    public static func sampleAge(index: Int, count: Int) -> Double {
        Double(max(0, count - 1 - index)) * LorenzConfiguration.timestep
    }
    public func opacity(age: Double, historyDuration: Double? = nil) -> Double {
        guard isValid, age.isFinite else { return 0 }
        let age = max(0, age)
        var alpha = age <= delay ? 1 : (duration == 0 ? 0 : 1 - Self.smoothstep((age-delay)/duration))
        if let capacity = historyDuration {
            guard capacity.isFinite, capacity > 0 else { return 0 }
            alpha *= Self.smoothstep((capacity-age)/min(0.25, capacity/4))
        }
        return alpha
    }
    public func visibleSegments(historyLength: Int) -> Int {
        guard isValid, historyLength >= 2 else { return 0 }
        return min(historyLength - 1, Int(ceil((delay+duration)/LorenzConfiguration.timestep)) + 1)
    }
    private static func smoothstep(_ value: Double) -> Double {
        let t = min(1, max(0, value)); return t*t*(3-2*t)
    }
}

// CPU reference for the GPU's rotation-minimizing frame. No generated CPU geometry is rendered.
public enum RibbonGeometry {
    public static func unit(_ v: SIMD3<Double>, fallback: SIMD3<Double>) -> SIMD3<Double> {
        let length = simd_length_squared(v)
        return length.isFinite && length > 1e-16 ? v / sqrt(length) : fallback
    }
    public static func initialSide(tangent: SIMD3<Double>) -> SIMD3<Double> {
        let t = unit(tangent, fallback: SIMD3(1,0,0))
        let a = abs(t)
        let axis = a.x <= a.y && a.x <= a.z ? SIMD3<Double>(1,0,0) : (a.y <= a.z ? SIMD3<Double>(0,1,0) : SIMD3<Double>(0,0,1))
        return unit(cross(t, axis), fallback: SIMD3(0,1,0))
    }
    public static func transport(side: SIMD3<Double>, from oldTangent: SIMD3<Double>, to newTangent: SIMD3<Double>) -> SIMD3<Double> {
        let a = unit(oldTangent, fallback: SIMD3(1,0,0))
        let b = unit(newTangent, fallback: a)
        let previous = unit(side - a*dot(side,a), fallback: initialSide(tangent: a))
        let axis = cross(a,b), cosine = min(1, max(-1, dot(a,b)))
        var result = previous
        if cosine > -0.9999 {
            result += cross(axis, previous) + cross(axis, cross(axis, previous))/(1+cosine)
        }
        result = unit(result - b*dot(result,b), fallback: initialSide(tangent: b))
        return dot(result, previous) < 0 ? -result : result
    }
    public static func pack(_ side: SIMD3<Double>) -> UInt32 {
        let n = unit(side, fallback: SIMD3(0,1,0))
        var p = SIMD2(n.x,n.y)/(abs(n.x)+abs(n.y)+abs(n.z))
        if n.z < 0 { p = (SIMD2(repeating: 1)-abs(SIMD2(p.y,p.x))) * SIMD2(p.x >= 0 ? 1 : -1, p.y >= 0 ? 1 : -1) }
        let u = UInt32(((p.x*0.5+0.5)*4095).rounded())
        let v = UInt32(((p.y*0.5+0.5)*4095).rounded())
        return u | (v << 12)
    }
    public static func unpack(_ packed: UInt32) -> SIMD3<Double> {
        let quantized = SIMD2<Double>(Double(packed & 4095), Double((packed >> 12) & 4095))
        let p = quantized * (2.0/4095.0) - SIMD2<Double>(repeating: 1)
        var n = SIMD3(p.x,p.y,1-abs(p.x)-abs(p.y))
        if n.z < 0 {
            n.x = (1-abs(p.y))*(p.x >= 0 ? 1 : -1)
            n.y = (1-abs(p.x))*(p.y >= 0 ? 1 : -1)
        }
        return unit(n, fallback: SIMD3(0,1,0))
    }
}
