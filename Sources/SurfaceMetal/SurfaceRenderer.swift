import Metal
import simd
import WorkspaceCore

private struct SurfaceUniforms {
    var matrix: simd_float4x4
    var eye: SIMD4<Float>
    var style: SIMD4<Float>
    var viewport: SIMD4<Float>
    var grid: SIMD4<Float>
}
private struct GridVertex { var point: SIMD4<Float>; var color: SIMD4<Float> }
private enum SurfaceMeshKey: Equatable { case parametric(SurfaceParameters), ellis(EllisWormhole) }

@MainActor
public final class SurfaceRenderer {
    public let device: any MTLDevice
    public let queue: any MTLCommandQueue
    private let library: any MTLLibrary
    private let surfacePipeline: any MTLRenderPipelineState
    private let gridPipeline: any MTLRenderPipelineState
    private var alphaPipeline: (any MTLRenderPipelineState)?
    private var depthPipeline: (any MTLRenderPipelineState)?
    private let depthState: any MTLDepthStencilState
    private let gridDepthState: any MTLDepthStencilState
    private var vertices: (any MTLBuffer)?
    private var indices: (any MTLBuffer)?
    private var gridBuffer: (any MTLBuffer)?
    private var throatBuffer: (any MTLBuffer)?
    private var throatConfiguration: SIMD2<Double>?
    private var meshKey: SurfaceMeshKey?
    private var gridConfiguration: CoordinateGrid?
    private var indexCount = 0, gridSegmentCount = 0
    public private(set) var meshBuildCount = 0

    private static func pipeline(device: any MTLDevice, library: any MTLLibrary, vertex: String, fragment: String,
                                 blend: Bool, depthOnly: Bool = false) throws -> any MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: vertex)
        descriptor.fragmentFunction = library.makeFunction(name: fragment)
        descriptor.depthAttachmentPixelFormat = .depth32Float
        let color = descriptor.colorAttachments[0]!
        color.pixelFormat = .bgra8Unorm_srgb; color.isBlendingEnabled = blend
        color.sourceRGBBlendFactor = .one; color.destinationRGBBlendFactor = .oneMinusSourceAlpha
        color.sourceAlphaBlendFactor = .one; color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        if depthOnly { color.writeMask = [] }
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    public init(device: any MTLDevice) throws {
        self.device = device
        guard let queue = device.makeCommandQueue() else { throw SurfaceError.resourceFailure }
        self.queue = queue
        let options = MTLCompileOptions()
        if #available(macOS 15, *) { options.mathMode = .safe } else { options.fastMathEnabled = false }
        let library = try device.makeLibrary(source: surfaceShaderSource,options: options)
        self.library = library
        surfacePipeline = try Self.pipeline(device: device,library: library,vertex: "surfaceVertex",fragment: "surfaceFragment",blend: false)
        gridPipeline = try Self.pipeline(device: device,library: library,vertex: "coordinateVertex",fragment: "coordinateFragment",blend: true)
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .lessEqual; descriptor.isDepthWriteEnabled = true
        guard let depth = device.makeDepthStencilState(descriptor: descriptor) else { throw SurfaceError.resourceFailure }
        depthState = depth
        descriptor.isDepthWriteEnabled = false
        guard let gridDepth = device.makeDepthStencilState(descriptor: descriptor) else { throw SurfaceError.resourceFailure }
        gridDepthState = gridDepth
    }
    private func upload(_ mesh: SurfaceMesh, key: SurfaceMeshKey) throws {
        guard let vertexBuffer = device.makeBuffer(bytes: mesh.vertices,length: mesh.vertices.count*MemoryLayout<SurfaceVertex>.stride,options: .storageModeShared),
              let indexBuffer = device.makeBuffer(bytes: mesh.indices,length: mesh.indices.count*MemoryLayout<UInt32>.stride,options: .storageModeShared) else { throw SurfaceError.resourceFailure }
        vertices = vertexBuffer; indices = indexBuffer; indexCount = mesh.indices.count
        meshKey = key; meshBuildCount += 1
        vertexBuffer.label = "Parametric surface vertices"; indexBuffer.label = "Parametric surface triangles"
    }
    private func prepareGrid(_ grid: CoordinateGrid) throws {
        if grid.visible && gridConfiguration != grid {
            let points = grid.segments.flatMap { line in
                [GridVertex(point: SIMD4(SIMD3<Float>(line.a),1),color: line.color),GridVertex(point: SIMD4(SIMD3<Float>(line.b),1),color: line.color)]
            }
            guard let buffer = device.makeBuffer(bytes: points,length: points.count*MemoryLayout<GridVertex>.stride,options: .storageModeShared) else { throw SurfaceError.resourceFailure }
            gridBuffer = buffer; gridSegmentCount = points.count/2; gridConfiguration = grid
            buffer.label = "Coordinate planes, axes and ticks"
        }
    }
    // Existing M2 path: same topology, material, depth and single-pass behavior.
    public func encode(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor,
                       parameters value: SurfaceParameters, camera: OrbitCamera, style: SurfaceStyle,
                       surfaceDensity: Int, grid: CoordinateGrid, size: SIMD2<Float>) throws {
        guard value.isValid else { throw SurfaceError.invalidParameters }
        let key = SurfaceMeshKey.parametric(value)
        if meshKey != key { try upload(SurfaceMesh(parameters: value),key: key) }
        try draw(into: command,pass: pass,camera: camera,style: style,density: surfaceDensity,grid: grid,size: size,
                 drawSurface: true,opacity: 1,meshVisible: true,throat: nil,funnel: nil)
    }
    public func encode(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor,
                       ellis: EllisWormhole, appearance: WormholeSurfaceAppearance, camera: OrbitCamera,
                       surfaceDensity: Int, grid: CoordinateGrid, size: SIMD2<Float>) throws {
        guard ellis.isValid, appearance.isValid else { throw SurfaceError.invalidParameters }
        let show = appearance.mode != .trajectories && appearance.opacity > 0
        let key = SurfaceMeshKey.ellis(ellis)
        if show && meshKey != key { try upload(SurfaceMesh(ellis: ellis,columns: ellis.funnel?.roundedReturnEdge == true ? 256 : 192),key: key) }
        let neckY = -(ellis.funnel?.depth ?? 0)
        let reference = SIMD2(ellis.throatRadius,neckY)
        if appearance.throatVisible && throatConfiguration != reference {
            var points: [GridVertex] = []; points.reserveCapacity(256)
            let color = SIMD4<Float>(0.40,0.58,0.64,1)
            for i in 0..<128 {
                for j in [i,i+1] {
                    let angle = Double(j)*2 * .pi/128
                    points.append(GridVertex(point: SIMD4(Float(ellis.throatRadius*cos(angle)),Float(neckY),Float(ellis.throatRadius*sin(angle)),1),color: color))
                }
            }
            guard let buffer = device.makeBuffer(bytes: points,length: points.count*MemoryLayout<GridVertex>.stride,options: .storageModeShared) else { throw SurfaceError.resourceFailure }
            throatBuffer = buffer; throatConfiguration = reference; buffer.label = "Ellis throat l=0 reference"
        }
        try draw(into: command,pass: pass,camera: camera,style: appearance.mode == .wireframe ? .wireframe : .shaded,
                 density: surfaceDensity,grid: grid,size: size,drawSurface: show,opacity: Float(appearance.opacity),
                 meshVisible: appearance.mode == .wireframe || appearance.meshVisible,throat: appearance.throatVisible ? throatBuffer : nil,funnel: ellis.funnel,
                 returnWidth: ellis.funnel?.roundedReturnEdge == true ? RoundedWormhole(geometry: ellis).width : 0)
    }
    private func draw(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor, camera: OrbitCamera,
                      style: SurfaceStyle, density: Int, grid: CoordinateGrid, size: SIMD2<Float>,
                      drawSurface: Bool, opacity: Float, meshVisible: Bool, throat: (any MTLBuffer)?, funnel: LegacyFunnelProfile?, returnWidth: Double = 0) throws {
        guard grid.isValid, (12...96).contains(density), size.x.isFinite, size.y.isFinite, size.x > 0, size.y > 0 else { throw SurfaceError.invalidParameters }
        try prepareGrid(grid)
        if drawSurface && opacity < 1 && alphaPipeline == nil {
            let alpha = try Self.pipeline(device: device,library: library,vertex: "surfaceVertex",fragment: "surfaceFragment",blend: true)
            let depth = try Self.pipeline(device: device,library: library,vertex: "surfaceVertex",fragment: "surfaceFragment",blend: false,depthOnly: true)
            alphaPipeline = alpha; depthPipeline = depth
        }
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw SurfaceError.resourceFailure }
        encoder.label = "Parametric surface and coordinates"; encoder.setCullMode(.none)
        encoder.setDepthStencilState(depthState)
        var uniforms = SurfaceUniforms(matrix: CameraProjection.matrix(camera: camera,aspect: size.x/size.y),
                                       eye: SIMD4(CameraProjection.cameraPosition(camera),1),
                                       style: SIMD4(Float(density),Float(density/2),style == .shaded ? 1 : 0,opacity),
                                       viewport: SIMD4(size.x,size.y,meshVisible ? 1 : 0,0),
                                       grid: SIMD4(funnel == nil ? 0 : 1,Float(funnel?.fieldHalfExtent ?? 0),Float((funnel?.fieldHalfExtent ?? 0)-returnWidth),Float(returnWidth)))
        encoder.setVertexBytes(&uniforms,length: MemoryLayout<SurfaceUniforms>.stride,index: 1)
        encoder.setFragmentBytes(&uniforms,length: MemoryLayout<SurfaceUniforms>.stride,index: 1)
        if drawSurface, let vertices, let indices {
            encoder.setVertexBuffer(vertices,offset: 0,index: 0)
            if opacity < 1, let depthPipeline, let alphaPipeline {
                // Nearest-sheet coverage: depth prepass avoids alpha accumulation on
                // overlapping sheets. Occluded trajectories stay occluded until hidden.
                encoder.setRenderPipelineState(depthPipeline)
                encoder.drawIndexedPrimitives(type: .triangle,indexCount: indexCount,indexType: .uint32,indexBuffer: indices,indexBufferOffset: 0)
                encoder.setDepthStencilState(gridDepthState); encoder.setRenderPipelineState(alphaPipeline)
            } else { encoder.setRenderPipelineState(surfacePipeline) }
            encoder.drawIndexedPrimitives(type: .triangle,indexCount: indexCount,indexType: .uint32,indexBuffer: indices,indexBufferOffset: 0)
        }
        encoder.setDepthStencilState(gridDepthState)
        encoder.setRenderPipelineState(gridPipeline)
        if grid.visible, let gridBuffer {
            encoder.setVertexBuffer(gridBuffer,offset: 0,index: 0)
            encoder.drawPrimitives(type: .triangle,vertexStart: 0,vertexCount: gridSegmentCount*6)
        }
        if let throat {
            encoder.setDepthBias(-2,slopeScale: -1,clamp: 0)
            encoder.setVertexBuffer(throat,offset: 0,index: 0)
            encoder.drawPrimitives(type: .triangle,vertexStart: 0,vertexCount: 128*6)
        }
        encoder.endEncoding()
    }
}
