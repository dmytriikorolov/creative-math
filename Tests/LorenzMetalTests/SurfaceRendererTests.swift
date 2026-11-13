import Metal
import Testing
import simd
import WorkspaceCore
import SurfaceMetal
@testable import LorenzMetal

@MainActor
@Test func surfaceCameraProjectionMatchesExistingLorenzConvention() {
    for preset in SurfacePreset.allCases {
        for aspect: Float in [0.75,1,1.6,2] {
            let camera = preset.camera
            #expect(CameraProjection.matrix(camera: camera, aspect: aspect) == LorenzTrails.matrix(camera: camera, aspect: aspect))
            let center = CameraProjection.matrix(camera: camera, aspect: aspect)*SIMD4<Float>(0,0,0,1)
            #expect(center.w > 0 && center.z > 0 && center.z < center.w)
        }
    }
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal unavailable; surface raster and resource validation NOT RUN"))
func surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try SurfaceRenderer(device: device)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb,width: 256,height: 256,mipmapped: false)
    descriptor.usage = .renderTarget; descriptor.storageMode = .private
    let color = try #require(device.makeTexture(descriptor: descriptor))
    descriptor.pixelFormat = .depth32Float
    let depth = try #require(device.makeTexture(descriptor: descriptor))
    let staging = try #require(device.makeBuffer(length: 256*256*4,options: .storageModeShared))
    func image(_ parameters: SurfaceParameters, style: SurfaceStyle = .wireframe, grid: CoordinateGrid = CoordinateGrid(), density: Int = 48) throws -> [UInt8] {
        let command = try #require(renderer.queue.makeCommandBuffer())
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = color; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.002428,green: 0.002732,blue: 0.003347,alpha: 1)
        pass.depthAttachment.texture = depth; pass.depthAttachment.loadAction = .clear; pass.depthAttachment.storeAction = .dontCare
        pass.depthAttachment.clearDepth = 1
        try renderer.encode(into: command,pass: pass,parameters: parameters,camera: parameters.preset.camera,
                            style: style,surfaceDensity: density,grid: grid,size: SIMD2(256,256))
        let blit = try #require(command.makeBlitCommandEncoder())
        blit.copy(from: color,sourceSlice: 0,sourceLevel: 0,sourceOrigin: MTLOrigin(x: 0,y: 0,z: 0),
                  sourceSize: MTLSize(width: 256,height: 256,depth: 1),to: staging,destinationOffset: 0,
                  destinationBytesPerRow: 1024,destinationBytesPerImage: 256*256*4)
        blit.endEncoding(); command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
        return Array(UnsafeBufferPointer(start: staging.contents().assumingMemoryBound(to: UInt8.self),count: 256*256*4))
    }
    for preset in SurfacePreset.allCases {
        let parameters = preset.parameters
        let wire = try image(parameters)
        #expect(wire.contains { $0 > 35 && $0 < 255 })
        let builds = renderer.meshBuildCount
        #expect(try image(parameters) == wire)
        #expect(renderer.meshBuildCount == builds)
        #expect(try image(parameters,style: .shaded) != wire)
        var grid = CoordinateGrid(); grid.visible = true
        #expect(try image(parameters,grid: grid) != wire)
        #expect(try image(parameters,density: 24) != wire)
        #expect(renderer.meshBuildCount == builds)
        var edited = parameters
        if preset == .wormhole { edited.depth = 0 } else { edited.tubeRadius = 1 }
        #expect(try image(edited) != wire)
        #expect(renderer.meshBuildCount == builds+1)
    }
}

@MainActor
@Test func cameraCanFocusATargetWithoutChangingExistingZoomLimits() {
    var camera = SurfacePreset.torus.camera
    camera.target = SIMD3(4,2,-3)
    let matrix = CameraProjection.matrix(camera: camera,aspect: 1.6)
    let projected = matrix*SIMD4(SIMD3<Float>(camera.target),1)
    #expect(abs(projected.x/projected.w) < 1e-6 && abs(projected.y/projected.w) < 1e-6)
    camera.zoom(-100,minimumDistance: 1)
    #expect(camera.distance == 1)
    var original = OrbitCamera()
    original.zoom(-100)
    #expect(original.distance == 35 && original.target == .zero)
}

@MainActor
@Test func followCameraTracksEveryStepWithoutRotatingOrZooming() throws {
    var solver = try TorusGeodesicSolver(configuration: TorusGeodesicConfiguration())
    var camera = SurfacePreset.torus.camera
    camera.pan = SIMD2(3,-2)
    var tracking = ParticleCameraTracking()
    let initial = camera
    tracking.setFollowing(true,camera: &camera,particle: solver.position)
    #expect(camera.pan == .zero)
    for _ in 0..<2400 {
        try solver.advance(steps: 1)
        let frame = tracking.resolved(camera: camera,particle: solver.position)
        #expect(frame.target == solver.position)
        #expect(frame.yaw == initial.yaw && frame.pitch == initial.pitch && frame.distance == initial.distance)
        let clip = CameraProjection.matrix(camera: frame,aspect: 1.6)*SIMD4(SIMD3<Float>(solver.position),1)
        #expect(abs(clip.x/clip.w) < 1e-6 && abs(clip.y/clip.w) < 1e-6)
    }
    // Orbit, zoom and deliberate pan continue to work during following.
    camera.orbit(x: 20,y: -10); camera.zoom(-0.2,minimumDistance: 1)
    camera.translate(x: 10,y: 5,viewportHeight: 900)
    let adjusted = tracking.resolved(camera: camera,particle: solver.position)
    #expect(adjusted.yaw == camera.yaw && adjusted.pitch == camera.pitch)
    #expect(adjusted.distance == camera.distance && adjusted.pan == camera.pan)
    tracking.setFollowing(false,camera: &camera,particle: solver.position)
    let frozen = camera
    try solver.advance(steps: 100)
    #expect(tracking.resolved(camera: camera,particle: solver.position) == frozen)
    tracking.setFollowing(true,camera: &camera,particle: solver.position)
    tracking.reset(camera: &camera,preset: SurfacePreset.torus.camera)
    #expect(!tracking.isFollowing && camera == SurfacePreset.torus.camera)
}

@MainActor
@Test func followCameraRespectsPausedStepRestartAndInvalidTargets() throws {
    var playback = try GeodesicPlayback(configuration: TorusGeodesicConfiguration())
    playback.isPaused = true
    var tracking = ParticleCameraTracking(), camera = SurfacePreset.torus.camera
    tracking.setFollowing(true,camera: &camera,particle: playback.solver.position)
    let frame = tracking.resolved(camera: camera,particle: playback.solver.position)
    try playback.advance(elapsed: 300)
    #expect(tracking.resolved(camera: camera,particle: playback.solver.position) == frame)
    try playback.singleStep()
    #expect(tracking.resolved(camera: camera,particle: playback.solver.position).target != frame.target)
    playback.restart()
    #expect(tracking.isFollowing && tracking.resolved(camera: camera,particle: playback.solver.position) == frame)
    tracking.setFollowing(false,camera: &camera,particle: SIMD3(.nan,0,0))
    #expect(tracking.isFollowing) // Invalid targets do not alter the mode or base camera.
    #expect(tracking.resolved(camera: camera,particle: SIMD3(.infinity,0,0)) == camera)
}
