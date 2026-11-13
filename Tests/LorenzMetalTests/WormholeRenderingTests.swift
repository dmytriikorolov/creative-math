import Metal
import Testing
import WorkspaceCore
import SurfaceMetal

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil,"Metal unavailable; Ellis material/modes/visibility/depth NOT RUN"))
func ellisRendererModesReuseGeometryAndDrawActualTrajectories() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try SurfaceRenderer(device: device), trails = try GeodesicTrails(device: device)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,width: 256,height: 256,mipmapped: false)
    descriptor.storageMode = .private; descriptor.usage = .renderTarget
    let color = try #require(device.makeTexture(descriptor: descriptor))
    descriptor.pixelFormat = .depth32Float
    let depth = try #require(device.makeTexture(descriptor: descriptor))
    let staging = try #require(device.makeBuffer(length: 256*256*4,options: .storageModeShared))
    var slot = 0
    func image(_ geometry: EllisWormhole = EllisWormhole(), material: WormholeSurfaceAppearance = WormholeSurfaceAppearance(),
               playback: WormholePlayback? = nil, marker: GeodesicAppearance = GeodesicAppearance(), ballNormal: SIMD3<Double>? = nil, grid: CoordinateGrid = CoordinateGrid()) throws -> [UInt8] {
        let command = try #require(renderer.queue.makeCommandBuffer())
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = color; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.002428,green: 0.002732,blue: 0.003347,alpha: 1)
        pass.depthAttachment.texture = depth; pass.depthAttachment.loadAction = .clear; pass.depthAttachment.storeAction = .store; pass.depthAttachment.clearDepth = 1
        try renderer.encode(into: command,pass: pass,ellis: geometry,appearance: material,camera: geometry.camera,surfaceDensity: 48,grid: grid,size: SIMD2(256,256))
        if let playback {
            pass.colorAttachments[0].loadAction = .load; pass.depthAttachment.loadAction = .load
            try trails.encodeBatch(into: command,pass: pass,
                                   tracks: [GeodesicRenderTrack(trail: playback.trail,particle: playback.presentationPosition,appearance: marker,ballNormal: ballNormal)],
                                   fade: TrailFade(delay: 20,duration: 12),camera: geometry.camera,size: SIMD2(256,256),slot: slot,depthTolerance: 0.01)
        }
        let blit = try #require(command.makeBlitCommandEncoder())
        blit.copy(from: color,sourceSlice: 0,sourceLevel: 0,sourceOrigin: MTLOrigin(x: 0,y: 0,z: 0),sourceSize: MTLSize(width: 256,height: 256,depth: 1),
                  to: staging,destinationOffset: 0,destinationBytesPerRow: 1024,destinationBytesPerImage: 256*256*4)
        blit.endEncoding(); command.commit(); command.waitUntilCompleted(); slot = (slot+1)%3
        #expect(command.status == .completed)
        return Array(UnsafeBufferPointer(start: staging.contents().assumingMemoryBound(to: UInt8.self),count: 256*256*4))
    }
    var material = WormholeSurfaceAppearance()
    let shaded = try image(material: material)
    #expect(try image(material: material) == shaded)
    var front = WormholeConfiguration(); front.initialL = 0
    front.initialPhi = .pi/2-EllisWormhole().camera.yaw
    var frontPlayback = try WormholePlayback(configuration: front); frontPlayback.isPaused = true
    var pointOnly = GeodesicAppearance(); pointOnly.trailVisible = false; pointOnly.particleDiameterPoints = 4
    #expect(try image(material: material,playback: frontPlayback,marker: pointOnly) != shaded)
    var back = front; back.initialPhi += .pi
    var backPlayback = try WormholePlayback(configuration: back); backPlayback.isPaused = true
    #expect(try image(material: material,playback: backPlayback,marker: pointOnly) == shaded)
    var ball = pointOnly; ball.particleDiameterPoints = 16
    let normal = -front.geometry.normal(l: front.initialL,phi: front.initialPhi)
    let sphere = try image(material: material,playback: frontPlayback,marker: ball,ballNormal: normal)
    #expect(sphere != shaded)
    // Surface-normal direction must not offset the sphere from its trail head.
    #expect(try image(material: material,playback: frontPlayback,marker: ball,ballNormal: -normal) == sphere)
    #expect(sphere != (try image(material: material,playback: frontPlayback,marker: ball)))
    #expect(try image(material: material,playback: frontPlayback,marker: ball,ballNormal: normal) == sphere)
    material.mode = .wireframe
    #expect(try image(material: material) != shaded)
    material.mode = .surface; material.opacity = 1
    let opaque = try image(material: material)
    #expect(opaque != shaded)
    material.opacity = 0.25; material.meshVisible = false
    #expect(try image(material: material) != opaque)
    #expect(renderer.meshBuildCount == 1)
    material.mode = .trajectories; material.throatVisible = false
    let empty = try image(material: material)
    var playback = try WormholePlayback(configuration: WormholeConfiguration())
    for _ in 0..<360 { try playback.advance(elapsed: 1.0/60) }
    playback.isPaused = true
    let trajectory = try image(material: material,playback: playback)
    #expect(trajectory != empty)
    #expect(try image(material: material,playback: playback) == trajectory)
    var hidden = GeodesicAppearance(); hidden.particleVisible = false; hidden.trailVisible = false
    #expect(try image(material: material,playback: playback,marker: hidden) == empty)
    material.mode = .surface; material.opacity = 0
    #expect(try image(material: material) == empty)
    material.opacity = 1; material.throatVisible = true
    #expect(try image(EllisWormhole(throatRadius: 3),material: material) != opaque)
    #expect(renderer.meshBuildCount == 2)
    // Returning to accepted M2 geometry switches cache keys safely.
    let command = try #require(renderer.queue.makeCommandBuffer())
    let pass = MTLRenderPassDescriptor()
    pass.colorAttachments[0].texture = color; pass.colorAttachments[0].loadAction = .clear
    pass.depthAttachment.texture = depth; pass.depthAttachment.loadAction = .clear; pass.depthAttachment.clearDepth = 1
    try renderer.encode(into: command,pass: pass,parameters: SurfacePreset.torus.parameters,camera: SurfacePreset.torus.camera,
                        style: .wireframe,surfaceDensity: 48,grid: CoordinateGrid(),size: SIMD2(256,256))
    command.commit(); command.waitUntilCompleted()
    #expect(command.status == .completed && renderer.meshBuildCount == 3)
    var rounded = WormholeBeam().geometry
    rounded.funnel?.roundedReturnEdge = true
    material.mode = .wireframe; material.opacity = 1
    let joined = try image(rounded,material: material)
    #expect(joined != empty)
    #expect(try image(rounded,material: material) == joined)
    #expect(renderer.meshBuildCount == 4)

}
