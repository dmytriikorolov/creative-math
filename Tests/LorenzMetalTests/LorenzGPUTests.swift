import Metal
import simd
import Testing
import WorkspaceCore
@testable import LorenzMetal

@MainActor
@Test func cameraProjectionPreservesAxesDepthAndAspect() {
    let camera = OrbitCamera(yaw: 0, pitch: 0, distance: 105)
    let matrix = LorenzTrails.matrix(camera: camera, aspect: 1)
    let center = matrix * SIMD4<Float>(0,0,0,1)
    #expect(abs(center.x) < 1e-5 && abs(center.y) < 1e-5)
    #expect(center.z / center.w > 0 && center.z / center.w < 1)
    let right = matrix * SIMD4<Float>(1,0,0,1)
    let up = matrix * SIMD4<Float>(0,1,0,1)
    #expect(right.x > 0 && up.y > 0)
    let wide = LorenzTrails.matrix(camera: camera, aspect: 2) * SIMD4<Float>(1,0,0,1)
    #expect(abs(wide.x - right.x/2) < 1e-6)
    var panned = camera
    panned.pan.x = 10
    #expect((LorenzTrails.matrix(camera: panned, aspect: 1) * SIMD4<Float>(0,0,0,1)).x < 0)
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal device unavailable; GPU parity NOT RUN"))
func gpuMatchesCPUReferenceAndResets() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let gpu = try LorenzGPU(device: device, configuration: LorenzConfiguration())
    let stateResource = gpu.states, historyResource = gpu.history
    func advance(_ steps: Int, reset: Bool) throws {
        let command = try #require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: command, steps: steps, reset: reset)
        command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
    }
    try advance(240, reset: true)
    let first = try gpu.readback()
    for (index, state) in first.enumerated() {
        var reference = LorenzReference(index: UInt32(index))
        try reference.advance(steps: 240, parameters: LorenzParameters())
        let difference = SIMD3<Double>(state.point) - reference.point
        #expect(max(abs(difference.x), abs(difference.y), abs(difference.z)) < 0.005)
        #expect(state.count == 241 && state.head == 240 && state.restarts == 0)
    }
    try advance(240, reset: true)
    let second = try gpu.readback()
    #expect(first.map(\.point) == second.map(\.point))
    try advance(0, reset: true)
    for _ in 0..<10 { try advance(24, reset: false) }
    #expect(try gpu.readback().map(\.point) == first.map(\.point))
    try advance(3000, reset: false)
    let wrapped = try gpu.readback()
    #expect(wrapped.allSatisfy { $0.count == 2048 && $0.head == 1192 })
    var changed = gpu.configuration
    changed.parameters.rho = 30
    try gpu.configure(changed)
    let lastPoint = wrapped[0].point
    try advance(0, reset: false)
    let cleared = try gpu.readback()
    #expect(cleared[0].point == lastPoint && cleared[0].count == 1)
    #expect(gpu.states === stateResource && gpu.history === historyResource)
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal device unavailable; divergence recovery NOT RUN"))
func gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let gpu = try LorenzGPU(device: device, configuration: LorenzConfiguration())
    let command = try #require(gpu.queue.makeCommandBuffer())
    try gpu.encode(into: command, steps: 0)
    struct State { var point: SIMD4<Float>; var info: SIMD4<UInt32> }
    var invalid = State(point: SIMD4(.nan,0,0,1), info: SIMD4(0,1,0,0))
    let source = try #require(device.makeBuffer(bytes: &invalid, length: MemoryLayout<State>.stride, options: .storageModeShared))
    let blit = try #require(command.makeBlitCommandEncoder())
    blit.copy(from: source, sourceOffset: 0, to: gpu.states, destinationOffset: 0, size: MemoryLayout<State>.stride)
    blit.endEncoding()
    try gpu.encode(into: command, steps: 1)
    command.commit(); command.waitUntilCompleted()
    #expect(command.status == .completed)
    let value = try gpu.readback()[0]
    let difference = value.point - LorenzMath.initialPoint(index: 0, seed: gpu.configuration.seed)
    #expect(max(abs(difference.x), abs(difference.y), abs(difference.z)) < 1e-6)
    #expect(value.head == 0 && value.count == 1 && value.restarts == 1)
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal unavailable; ribbon rendering and frozen-aging verification NOT RUN"))
func gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    var configuration = LorenzPreset.sculpture.configuration
    configuration.trajectoryCount = 3; configuration.trailLength = 512
    let gpu = try LorenzGPU(device: device, configuration: configuration)
    func advance(_ steps: Int, reset: Bool = false, preRoll: Bool = false, frames: Bool = true) throws {
        let command = try #require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: command, steps: steps, reset: reset, preRoll: preRoll, ribbonFrames: frames)
        command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
    }
    try advance(240)
    let ribbonStates = try gpu.readback()
    for state in ribbonStates {
        let side = try #require(state.ribbonSide)
        let p = SIMD3<Double>(state.point)
        let v = LorenzMath.derivative(p, parameters: configuration.parameters)
        let t = RibbonGeometry.unit(SIMD3(v.x,v.z,-v.y), fallback: SIMD3(1,0,0))
        #expect(abs(simd_length(side)-1) < 1e-5)
        #expect(abs(dot(SIMD3<Double>(side),t)) < 0.003)
    }
    try advance(240, reset: true, frames: false)
    #expect(try gpu.readback().map(\.point) == ribbonStates.map(\.point))
    try advance(0, preRoll: true)
    let statesBefore = try gpu.readback()
    let renderer = try LorenzTrails(gpu: gpu)
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: 256, height: 256, mipmapped: false)
    descriptor.storageMode = .private; descriptor.usage = .renderTarget
    let texture = try #require(device.makeTexture(descriptor: descriptor))
    let staging = try #require(device.makeBuffer(length: 256*256*4, options: .storageModeShared))
    func pixels(_ appearance: LorenzAppearance) throws -> [UInt8] {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        let command = try #require(gpu.queue.makeCommandBuffer())
        try renderer.encode(into: command, pass: pass, gpu: gpu, camera: OrbitCamera(), appearance: appearance, size: SIMD2(256,256))
        let blit = try #require(command.makeBlitCommandEncoder())
        blit.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0,y: 0,z: 0),
                  sourceSize: MTLSize(width: 256,height: 256,depth: 1), to: staging, destinationOffset: 0,
                  destinationBytesPerRow: 1024, destinationBytesPerImage: 256*256*4)
        blit.endEncoding(); command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
        return Array(UnsafeBufferPointer(start: staging.contents().assumingMemoryBound(to: UInt8.self), count: 256*256*4))
    }
    var appearance = LorenzPreset.sculpture.appearance
    let first = try pixels(appearance)
    try advance(0) // Camera/redraw work during a pause must not advance history or age.
    #expect(try pixels(appearance) == first)
    let after = try gpu.readback()
    #expect(after.map(\.head) == statesBefore.map(\.head))
    #expect(after.map(\.point) == statesBefore.map(\.point))
    func colored(_ bytes: [UInt8]) -> Int {
        stride(from: 0,to: bytes.count,by: 4).filter { bytes[$0] > 0 || bytes[$0+1] > 0 || bytes[$0+2] > 0 }.count
    }
    #expect(colored(first) > 0)
    appearance.fade = TrailFade(delay: 0, duration: 0)
    #expect(try colored(pixels(appearance)) < colored(first))
    appearance.fade = LorenzPreset.sculpture.appearance.fade
    appearance.ribbonWidth = 0.04
    let narrow = try pixels(appearance)
    appearance.ribbonWidth = 1.2
    #expect(try colored(pixels(appearance)) > colored(narrow))
    appearance.representation = .line
    #expect(try colored(pixels(appearance)) > 0)
    #expect(gpu.history.length == configuration.historyBytes)
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal unavailable; ring history and preset transitions NOT RUN"))
func gpuRingContentsAndPresetTransitions() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    var configuration = LorenzConfiguration()
    configuration.trajectoryCount = 2; configuration.trailLength = 256
    let gpu = try LorenzGPU(device: device, configuration: configuration)
    func advance(_ steps: Int, reset: Bool = false, preRoll: Bool = false, ribbon: Bool = false) throws -> [TrajectorySnapshot] {
        let command = try #require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: command, steps: steps, reset: reset, preRoll: preRoll, ribbonFrames: ribbon)
        command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
        return try gpu.readback()
    }
    let at255 = try advance(255)
    #expect(at255.allSatisfy { $0.head == 255 && $0.count == 256 })
    let at256 = try advance(1)
    #expect(at256.allSatisfy { $0.head == 0 && $0.count == 256 })
    let at273 = try advance(17)
    #expect(at273.allSatisfy { $0.head == 17 && $0.count == 256 })
    let staging = try #require(device.makeBuffer(length: gpu.history.length, options: .storageModeShared))
    let command = try #require(gpu.queue.makeCommandBuffer())
    let blit = try #require(command.makeBlitCommandEncoder())
    blit.copy(from: gpu.history, sourceOffset: 0, to: staging, destinationOffset: 0, size: gpu.history.length)
    blit.endEncoding(); command.commit(); command.waitUntilCompleted()
    #expect(command.status == .completed)
    let samples = staging.contents().bindMemory(to: SIMD4<Float>.self, capacity: 512)
    for checkpoint in [at255, at256, at273] {
        for (index, state) in checkpoint.enumerated() {
            let actual = samples[index*256+Int(state.head)]
            #expect(SIMD3(actual.x,actual.y,actual.z) == state.point)
        }
    }
    // Edits keep positions, expose only one valid history point, and reuse resources.
    let history = gpu.history
    configuration.parameters.rho = 10
    try gpu.configure(configuration)
    let cleared = try advance(0)
    #expect(cleared.map(\.point) == at273.map(\.point))
    #expect(cleared.allSatisfy { $0.head == 0 && $0.count == 1 })
    #expect(gpu.history === history)
    for preset in [LorenzPreset.sculpture, .filament, .classic, .sculpture] {
        try gpu.configure(preset.configuration)
        let ribbon = preset.appearance.representation == .ribbon
        let first = try advance(0, preRoll: true, ribbon: ribbon)
        let second = try advance(0, reset: true, preRoll: true, ribbon: ribbon)
        #expect(first.map(\.point) == second.map(\.point))
        #expect(first.map(\.ribbonSide) == second.map(\.ribbonSide))
        #expect(first.count == preset.configuration.trajectoryCount)
        #expect(first.allSatisfy { $0.count == UInt32(preset.configuration.trailLength) && $0.restarts == 0 })
        #expect(gpu.integratedSteps == UInt64(LorenzConfiguration.warmupSteps+preset.configuration.trailLength-1))
        #expect(gpu.history.length == preset.configuration.historyBytes)
    }
}

@MainActor
@Test(.enabled(if: MTLCreateSystemDefaultDevice() != nil, "Metal unavailable; stable GPU equilibria NOT RUN"))
func gpuStableDynamicsSettleWithoutRestarting() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    for rho in [0.0, 0.5, 10.0] {
        var configuration = LorenzConfiguration()
        configuration.trajectoryCount = 2; configuration.trailLength = 256
        configuration.parameters.rho = rho
        let gpu = try LorenzGPU(device: device, configuration: configuration)
        let command = try #require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: command, steps: 24000, ribbonFrames: true)
        command.commit(); command.waitUntilCompleted()
        #expect(command.status == .completed)
        let x = sqrt(configuration.parameters.beta*max(0,rho-1))
        let target = rho < 1 ? SIMD3<Double>.zero : SIMD3(x,x,rho-1)
        for state in try gpu.readback() {
            #expect(LorenzMath.isSafe(SIMD3<Double>(state.point)))
            #expect(simd_length(SIMD3<Double>(state.point)-target) < 0.001)
            #expect(state.restarts == 0 && state.count == 256 && state.head == 192)
            #expect(abs(simd_length(try #require(state.ribbonSide))-1) < 1e-5)
        }
    }
}
