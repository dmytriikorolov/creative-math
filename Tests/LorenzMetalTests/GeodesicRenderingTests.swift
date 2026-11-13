import Foundation
import Metal
import Testing
import WorkspaceCore
import SurfaceMetal

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil,"Metal unavailable; geodesic raster/depth/frozen trail NOT RUN"))
func geodesicOverlayPreservesSurfaceDepthAndFrozenHistory() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try SurfaceRenderer(device: device), trails = try GeodesicTrails(device: device)
    var playback = try GeodesicPlayback(configuration: TorusGeodesicConfiguration(),trailLength: 1024)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,width: 256,height: 256,mipmapped: false)
    descriptor.storageMode = .private; descriptor.usage = .renderTarget
    let color = try #require(device.makeTexture(descriptor: descriptor))
    descriptor.pixelFormat = .depth32Float
    let depth = try #require(device.makeTexture(descriptor: descriptor))
    let staging = try #require(device.makeBuffer(length: 256*256*4,options: .storageModeShared))
    var slot = 0
    func image(overlay: Bool = true, camera: OrbitCamera = SurfacePreset.torus.camera, fade: TrailFade = TrailFade(delay: 12,duration: 18), appearance: GeodesicAppearance = GeodesicAppearance()) throws -> [UInt8] {
        let command = try #require(renderer.queue.makeCommandBuffer())
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = color; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.depthAttachment.texture = depth; pass.depthAttachment.loadAction = .clear; pass.depthAttachment.storeAction = .store
        pass.depthAttachment.clearDepth = 1
        try renderer.encode(into: command,pass: pass,parameters: SurfacePreset.torus.parameters,camera: camera,
                            style: .wireframe,surfaceDensity: 48,grid: CoordinateGrid(),size: SIMD2(256,256))
        if overlay {
            pass.colorAttachments[0].loadAction = .load; pass.depthAttachment.loadAction = .load
            try trails.encode(into: command,pass: pass,trail: playback.trail,fade: fade,camera: camera,size: SIMD2(256,256),slot: slot,appearance: appearance)
        }
        let blit = try #require(command.makeBlitCommandEncoder())
        blit.copy(from: color,sourceSlice: 0,sourceLevel: 0,sourceOrigin: MTLOrigin(x: 0,y: 0,z: 0),sourceSize: MTLSize(width: 256,height: 256,depth: 1),
                  to: staging,destinationOffset: 0,destinationBytesPerRow: 1024,destinationBytesPerImage: 256*256*4)
        blit.endEncoding(); command.commit(); command.waitUntilCompleted(); slot = (slot+1)%3
        #expect(command.status == .completed)
        return Array(UnsafeBufferPointer(start: staging.contents().assumingMemoryBound(to: UInt8.self),count: 256*256*4))
    }
    #expect(try image() != image(overlay: false)) // Visible initial particle.
    var small = GeodesicAppearance(); small.particleDiameterPoints = 4
    var large = small; large.particleDiameterPoints = 28
    func warmPixels(_ bytes: [UInt8]) -> Int {
        var count = 0
        for offset in stride(from: 0,to: bytes.count,by: 4) {
            let red = Int(bytes[offset+2]), green = Int(bytes[offset+1]), blue = Int(bytes[offset])
            if red > green+10 && red > blue+10 { count += 1 }
        }
        return count
    }
    #expect(try warmPixels(image(appearance: large)) > warmPixels(image(appearance: small)))
    // Focus an inner-equator point between mesh columns, where the chordal mesh
    // protrudes into the hole relative to the analytic circle.
    let initialPlayback = playback
    var inner = TorusGeodesicConfiguration(); inner.initialU = 0.47; inner.initialV = .pi
    playback = try GeodesicPlayback(configuration: inner,trailLength: 1024)
    var focused = SurfacePreset.torus.camera
    focused.target = playback.solver.position
    focused.yaw = atan2(-cos(inner.initialU),-sin(inner.initialU)); focused.pitch = 0; focused.distance = 1
    #expect(try image(camera: focused) != image(overlay: false,camera: focused))
    playback = initialPlayback
    var opposite = SurfacePreset.torus.camera
    opposite.yaw += .pi; opposite.pitch = -opposite.pitch
    #expect(try image(camera: opposite) == image(overlay: false,camera: opposite)) // Occluded particle.
    for _ in 0..<180 { try playback.advance(elapsed: 1.0/60) }
    let frame = try image()
    playback.isPaused = true
    try playback.advance(elapsed: 60)
    #expect(try image() == frame)
    #expect(try image(fade: TrailFade(delay: 0,duration: 0)) != frame)
    #expect(renderer.meshBuildCount == 1)
    playback.restart()
    #expect(playback.trail.count == 1)
    #expect(try image() != frame)
}
