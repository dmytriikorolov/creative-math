import Foundation
import simd

// Shared projection only; each scene retains its own camera state and target conventions.
public enum CameraProjection {
    public static let near: Float = 0.1
    public static let far: Float = 600
    public static func matrix(camera c: OrbitCamera, aspect: Float) -> simd_float4x4 {
        let eye = SIMD3<Float>(Float(sin(c.yaw)*cos(c.pitch)), Float(sin(c.pitch)), Float(cos(c.yaw)*cos(c.pitch))) * Float(c.distance)
        let forward = normalize(-eye)
        let right = normalize(cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = cross(right, forward)
        let position = cameraPosition(c)
        let view = simd_float4x4(rows: [SIMD4(right, -dot(right, position)), SIMD4(up, -dot(up, position)),
                                      SIMD4(-forward, dot(forward, position)), SIMD4(0,0,0,1)])
        let y: Float = 1 / tan(0.35), near = Self.near, far = Self.far
        let projection = simd_float4x4(columns: (SIMD4(y/aspect,0,0,0), SIMD4(0,y,0,0),
                                               SIMD4(0,0,far/(near-far),-1), SIMD4(0,0,near*far/(near-far),0)))
        return projection * view
    }
    public static func cameraPosition(_ c: OrbitCamera) -> SIMD3<Float> {
        let eye = SIMD3<Float>(Float(sin(c.yaw)*cos(c.pitch)), Float(sin(c.pitch)), Float(cos(c.yaw)*cos(c.pitch))) * Float(c.distance)
        let forward = normalize(-eye)
        let right = normalize(cross(forward,SIMD3<Float>(0,1,0)))
        let up = cross(right,forward)
        return SIMD3<Float>(c.target) + eye + right*Float(c.pan.x) + up*Float(c.pan.y)
    }
}

// Pure camera policy for a moving target. Following translates the camera rig only;
// orientation/distance stay under user control. Pan remains a deliberate framing offset.
public struct ParticleCameraTracking: Equatable, Sendable {
    public private(set) var isFollowing = false
    public init() {}
    public mutating func setFollowing(_ enabled: Bool, camera: inout OrbitCamera, particle: SIMD3<Double>) {
        guard (0..<3).allSatisfy({ particle[$0].isFinite }) else { return }
        if enabled != isFollowing {
            // Freeze the current tracked location on disable, avoiding a jump back
            // to the target stored before following began.
            camera.target = particle
            if enabled { camera.pan = .zero }
        }
        isFollowing = enabled
    }
    public func resolved(camera: OrbitCamera, particle: SIMD3<Double>) -> OrbitCamera {
        guard isFollowing, (0..<3).allSatisfy({ particle[$0].isFinite }) else { return camera }
        var result = camera; result.target = particle; return result
    }
    public mutating func reset(camera: inout OrbitCamera, preset: OrbitCamera) {
        isFollowing = false; camera = preset
    }
}

/// Camera-only follow policy for a reusable particle slot. Missing targets hold
/// the last camera target; relaunches reacquire without changing user intent.
public struct RelaunchCameraTracking: Sendable {
    public private(set) var isFollowing = false
    public private(set) var isWaiting = false
    public var isTransitioning: Bool { returnFrom != nil }
    private var target: SIMD3<Double>?
    private var returnFrom: SIMD3<Double>?
    private var returnElapsed = 0.0
    private let returnDuration = 0.6
    public init() {}
    public mutating func setFollowing(_ enabled: Bool,camera: inout OrbitCamera,particle: SIMD3<Double>?) {
        if !enabled {
            if isFollowing, let target { camera.target = target }
            isFollowing = false; isWaiting = false; returnFrom = nil
            return
        }
        if !isFollowing { camera.pan = .zero; target = camera.target }
        isFollowing = true
        select(particle: particle)
    }
    public mutating func select(particle: SIMD3<Double>?) {
        guard isFollowing else { return }
        returnFrom = nil; returnElapsed = 0
        if let particle, (0..<3).allSatisfy({ particle[$0].isFinite }) {
            target = particle; isWaiting = false
        } else { isWaiting = true }
    }
    public mutating func update(particle: SIMD3<Double>?,elapsed: Double,reduceMotion: Bool = false) {
        guard isFollowing else { return }
        guard let particle, (0..<3).allSatisfy({ particle[$0].isFinite }) else {
            isWaiting = true; returnFrom = nil; return
        }
        if isWaiting {
            returnFrom = target ?? particle; returnElapsed = 0; isWaiting = false
        }
        if reduceMotion { returnFrom = nil }
        if let from = returnFrom {
            if elapsed.isFinite { returnElapsed += max(0,min(0.25,elapsed)) }
            let t = min(1,returnElapsed/returnDuration)
            let weight = t*t*(3-2*t)
            target = from+(particle-from)*weight
            if t >= 1 { returnFrom = nil }
        } else { target = particle }
    }
    public func resolved(camera: OrbitCamera) -> OrbitCamera {
        guard isFollowing, let target else { return camera }
        var result = camera; result.target = target; return result
    }
    public mutating func reset(camera: inout OrbitCamera,preset: OrbitCamera) {
        self = Self(); camera = preset
    }
}
