import Foundation
import Metal
import WorkspaceCore

public struct TrajectorySnapshot: Sendable {
    public var point: SIMD3<Float>
    public var head: UInt32
    public var count: UInt32
    public var restarts: UInt32
    public var ribbonSide: SIMD3<Float>?
}

private struct SimulationUniforms {
    var model: SIMD4<Float>
    var config: SIMD4<UInt32>
    var flags: SIMD4<UInt32>
}

@MainActor
public final class LorenzGPU {
    public let device: any MTLDevice
    public let queue: any MTLCommandQueue
    public let library: any MTLLibrary
    public private(set) var configuration: LorenzConfiguration
    public private(set) var states: any MTLBuffer
    public private(set) var history: any MTLBuffer
    public private(set) var integratedSteps: UInt64 = 0
    private let initializePipeline: any MTLComputePipelineState
    private let integratePipeline: any MTLComputePipelineState
    private let clearPipeline: any MTLComputePipelineState
    private var needsReset = true
    private var needsClear = false
    public private(set) var tracksRibbonFrames = false

    public init(device: any MTLDevice, configuration: LorenzConfiguration) throws {
        guard configuration.isValid else { throw LorenzError.invalidConfiguration }
        self.device = device
        self.configuration = configuration
        guard let queue = device.makeCommandQueue(),
              let states = device.makeBuffer(length: configuration.trajectoryCount * 32, options: .storageModePrivate),
              let history = device.makeBuffer(length: configuration.historyBytes, options: .storageModePrivate) else {
            throw LorenzError.resourceFailure
        }
        self.queue = queue; self.states = states; self.history = history
        let options = MTLCompileOptions()
        if #available(macOS 15, *) { options.mathMode = .safe }
        else { options.fastMathEnabled = false }
        let compiledLibrary = try device.makeLibrary(source: lorenzShaderSource, options: options)
        library = compiledLibrary
        func pipeline(_ name: String) throws -> any MTLComputePipelineState {
            guard let function = compiledLibrary.makeFunction(name: name) else { throw LorenzError.resourceFailure }
            return try device.makeComputePipelineState(function: function)
        }
        initializePipeline = try pipeline("initializeTrajectories")
        integratePipeline = try pipeline("integrateTrajectories")
        clearPipeline = try pipeline("clearTrails")
        states.label = "Lorenz trajectory state"
        history.label = "Lorenz ring history"
    }

    public func configure(_ value: LorenzConfiguration) throws {
        guard value.isValid else { throw LorenzError.invalidConfiguration }
        if value.trajectoryCount != configuration.trajectoryCount || value.trailLength != configuration.trailLength {
            guard let newStates = device.makeBuffer(length: value.trajectoryCount * 32, options: .storageModePrivate),
                  let newHistory = device.makeBuffer(length: value.historyBytes, options: .storageModePrivate) else { throw LorenzError.resourceFailure }
            states = newStates; history = newHistory; needsReset = true
        } else if value.seed != configuration.seed { needsReset = true }
        else if value.parameters != configuration.parameters { needsClear = true }
        configuration = value
    }

    public func encode(into command: any MTLCommandBuffer, steps: Int, reset: Bool = false, preRoll: Bool = false, ribbonFrames: Bool = false) throws {
        guard (0...100000).contains(steps) else { throw LorenzError.invalidConfiguration }
        if tracksRibbonFrames != ribbonFrames { needsReset = true; tracksRibbonFrames = ribbonFrames }
        let restarting = needsReset || reset
        guard restarting || needsClear || steps > 0 else { return }
        guard let encoder = command.makeComputeCommandEncoder() else { throw LorenzError.resourceFailure }
        encoder.label = "Lorenz fixed-step RK4"
        encoder.setBuffer(states, offset: 0, index: 0)
        encoder.setBuffer(history, offset: 0, index: 1)
        let m = configuration.parameters
        var uniforms = SimulationUniforms(model: SIMD4(Float(m.sigma), Float(m.rho), Float(m.beta), Float(LorenzConfiguration.timestep)),
                                          config: SIMD4(UInt32(configuration.trajectoryCount), UInt32(configuration.trailLength), 0, configuration.seed),
                                          flags: SIMD4(ribbonFrames ? 1 : 0, 0, 0, 0))
        func dispatch(_ pipeline: any MTLComputePipelineState, count: Int) {
            uniforms.config.z = UInt32(count)
            encoder.setComputePipelineState(pipeline)
            encoder.setBytes(&uniforms, length: MemoryLayout<SimulationUniforms>.stride, index: 2)
            encoder.dispatchThreads(MTLSize(width: configuration.trajectoryCount, height: 1, depth: 1),
                                    threadsPerThreadgroup: MTLSize(width: min(64, pipeline.maxTotalThreadsPerThreadgroup), height: 1, depth: 1))
            encoder.memoryBarrier(scope: .buffers)
        }
        if restarting { dispatch(initializePipeline, count: 0); integratedSteps = 0 }
        else if needsClear { dispatch(clearPipeline, count: 0) }
        var remaining = steps + (restarting && preRoll ? LorenzConfiguration.warmupSteps + configuration.trailLength - 1 : 0)
        integratedSteps += UInt64(remaining)
        while remaining > 0 {
            let count = min(remaining, 256)
            dispatch(integratePipeline, count: count)
            remaining -= count
        }
        encoder.endEncoding()
        needsReset = false; needsClear = false
    }

    // Validation only: no rendering-frame path calls this or waits for GPU completion.
    public func readback() throws -> [TrajectorySnapshot] {
        guard let staging = device.makeBuffer(length: states.length, options: .storageModeShared),
              let command = queue.makeCommandBuffer(), let blit = command.makeBlitCommandEncoder() else { throw LorenzError.resourceFailure }
        blit.copy(from: states, sourceOffset: 0, to: staging, destinationOffset: 0, size: states.length)
        blit.endEncoding(); command.commit(); command.waitUntilCompleted()
        guard command.status == .completed else { throw command.error ?? LorenzError.resourceFailure }
        struct State { var point: SIMD4<Float>; var info: SIMD4<UInt32> }
        let values = staging.contents().bindMemory(to: State.self, capacity: configuration.trajectoryCount)
        return (0..<configuration.trajectoryCount).map {
            TrajectorySnapshot(point: SIMD3(values[$0].point.x, values[$0].point.y, values[$0].point.z),
                               head: values[$0].info.x, count: values[$0].info.y, restarts: values[$0].info.z,
                               ribbonSide: tracksRibbonFrames ? SIMD3<Float>(RibbonGeometry.unpack(UInt32(values[$0].point.w))) : nil)
        }
    }
}
