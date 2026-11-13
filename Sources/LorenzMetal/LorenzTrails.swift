import Metal
import simd
import WorkspaceCore

private struct DrawUniforms {
    var matrix: simd_float4x4
    var viewport: SIMD4<Float>
    var config: SIMD4<UInt32>
    var low: SIMD4<Float>
    var high: SIMD4<Float>
    var fading: SIMD4<Float>
    var eye: SIMD4<Float>
}

@MainActor
public final class LorenzTrails {
    private let pipeline: any MTLRenderPipelineState
    private let sculpturePipeline: any MTLRenderPipelineState
    public init(gpu: LorenzGPU, pixelFormat: MTLPixelFormat = .bgra8Unorm_srgb) throws {
        let descriptor = MTLRenderPipelineDescriptor()
        let color = descriptor.colorAttachments[0]!
        color.pixelFormat = pixelFormat
        color.isBlendingEnabled = true
        color.sourceRGBBlendFactor = .one
        color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one
        color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.vertexFunction = gpu.library.makeFunction(name: "trailVertex")
        descriptor.fragmentFunction = gpu.library.makeFunction(name: "trailFragment")
        pipeline = try gpu.device.makeRenderPipelineState(descriptor: descriptor)
        descriptor.vertexFunction = gpu.library.makeFunction(name: "sculptureVertex")
        descriptor.fragmentFunction = gpu.library.makeFunction(name: "sculptureFragment")
        sculpturePipeline = try gpu.device.makeRenderPipelineState(descriptor: descriptor)
    }
    public func encode(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor,
                       gpu: LorenzGPU, camera: OrbitCamera, appearance: LorenzAppearance, size: SIMD2<Float>) throws {
        guard appearance.isValid else { throw LorenzError.invalidConfiguration }
        guard appearance.representation != .ribbon || gpu.tracksRibbonFrames else { throw LorenzError.invalidConfiguration }
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw LorenzError.resourceFailure }
        encoder.label = appearance.representation == .ribbon ? "Lorenz spatial ribbons" : "Lorenz analytic lines"
        encoder.setRenderPipelineState(appearance.representation == .ribbon ? sculpturePipeline : pipeline)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(gpu.states, offset: 0, index: 0)
        encoder.setVertexBuffer(gpu.history, offset: 0, index: 1)
        let visible = appearance.fade.visibleSegments(historyLength: gpu.configuration.trailLength)
        var uniforms = DrawUniforms(matrix: Self.matrix(camera: camera, aspect: max(0.01, size.x / max(1, size.y))),
                                    viewport: SIMD4(max(1, size.x), max(1, size.y), appearance.widthPixels, appearance.opacity),
                                    config: SIMD4(UInt32(gpu.configuration.trajectoryCount), UInt32(gpu.configuration.trailLength), UInt32(visible), 0),
                                    low: appearance.low, high: appearance.high,
                                    fading: SIMD4(Float(appearance.fade.delay), Float(appearance.fade.duration), Float(LorenzConfiguration.timestep), Float(appearance.ribbonWidth)),
                                    eye: SIMD4(Self.cameraPosition(camera),1))
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<DrawUniforms>.stride, index: 2)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0,
                               vertexCount: 6 * visible, instanceCount: gpu.configuration.trajectoryCount)
        encoder.endEncoding()
    }
    static func matrix(camera c: OrbitCamera, aspect: Float) -> simd_float4x4 {
        let eye = SIMD3<Float>(Float(sin(c.yaw)*cos(c.pitch)), Float(sin(c.pitch)), Float(cos(c.yaw)*cos(c.pitch))) * Float(c.distance)
        let forward = normalize(-eye)
        let right = normalize(cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = cross(right, forward)
        let position = cameraPosition(c)
        let view = simd_float4x4(rows: [SIMD4(right, -dot(right, position)), SIMD4(up, -dot(up, position)),
                                      SIMD4(-forward, dot(forward, position)), SIMD4(0,0,0,1)])
        let y: Float = 1 / tan(0.35), near: Float = 0.1, far: Float = 600
        let projection = simd_float4x4(columns: (SIMD4(y/aspect,0,0,0), SIMD4(0,y,0,0),
                                               SIMD4(0,0,far/(near-far),-1), SIMD4(0,0,near*far/(near-far),0)))
        return projection * view
    }
    private static func cameraPosition(_ c: OrbitCamera) -> SIMD3<Float> {
        let eye = SIMD3<Float>(Float(sin(c.yaw)*cos(c.pitch)), Float(sin(c.pitch)), Float(cos(c.yaw)*cos(c.pitch))) * Float(c.distance)
        let forward = normalize(-eye)
        let right = normalize(cross(forward,SIMD3<Float>(0,1,0)))
        let up = cross(right,forward)
        return eye + right*Float(c.pan.x) + up*Float(c.pan.y)
    }
}
