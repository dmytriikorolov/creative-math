import Foundation
import Metal
import WorkspaceCore
import LorenzMetal

// Real offscreen compute + graphics workload; device access is required even without a desktop.
@main
struct LorenzValidation {
    @MainActor
    static func main() async {
        do { try await run() }
        catch {
            print("NOT VERIFIED: \(error.localizedDescription)")
            Foundation.exit(2)
        }
    }
    @MainActor
    static func run() async throws {
        let args = Array(CommandLine.arguments.dropFirst())
        if args == ["--help"] || args == ["-h"] { print(LorenzValidationOptions.usage); return }
        let options = try LorenzValidationOptions(arguments: args)
        let preset = options.preset, representation = options.representation, seconds = options.seconds
        var appearance = preset.appearance
        appearance.representation = representation
        let outputURL = options.output.map { URL(fileURLWithPath: $0).standardizedFileURL }
        if let outputURL {
            let parent = outputURL.deletingLastPathComponent().path
            guard FileManager.default.isWritableFile(atPath: parent) else {
                throw LorenzValidationOptions.OptionsError.invalid("Output parent must exist and be writable: \(outputURL.path)")
            }
        }
        status("Mode: \(seconds > 0 ? "parity + offscreen benchmark (\(seconds) seconds)" : "parity only; no JSON requested").")
        let ribbonFrames = representation == .ribbon
        guard let device = MTLCreateSystemDefaultDevice() else { throw LorenzError.metalUnavailable }
        let gpu = try LorenzGPU(device: device, configuration: preset.configuration)
        let first = try require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: first, steps: 240, reset: true, ribbonFrames: ribbonFrames)
        await complete(first)
        guard first.status == .completed else { throw first.error ?? LorenzError.resourceFailure }
        let values = try gpu.readback()
        for (index, state) in values.enumerated() {
            var reference = LorenzReference(index: UInt32(index), seed: preset.configuration.seed)
            try reference.advance(steps: 240, parameters: preset.configuration.parameters)
            let d = SIMD3<Double>(state.point) - reference.point
            guard LorenzMath.isSafe(SIMD3<Double>(state.point)), max(abs(d.x), abs(d.y), abs(d.z)) < 0.005, state.restarts == 0 else {
                throw ValidationError.referenceMismatch
            }
        }
        print("GPU/CPU short-horizon parity: PASS (\(values.count) trajectories, 240 steps, absolute tolerance 0.005)")
        guard seconds > 0 else { return }
        let width = options.width, height = options.height
        status("Parity passed. Preparing offscreen render; JSON will be written after warm-up and the timed run.")
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget]; descriptor.storageMode = .private
        let texture = try require(device.makeTexture(descriptor: descriptor))
        let renderer = try LorenzTrails(gpu: gpu)
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.002428, green: 0.002732, blue: 0.003347, alpha: 1)
        let warmup = try require(gpu.queue.makeCommandBuffer())
        try gpu.encode(into: warmup, steps: 0, reset: true, preRoll: true, ribbonFrames: ribbonFrames)
        try renderer.encode(into: warmup, pass: pass, gpu: gpu, camera: preset.camera, appearance: appearance,
                            size: SIMD2(Float(width), Float(height)))
        await complete(warmup)
        guard warmup.status == .completed else { throw warmup.error ?? LorenzError.resourceFailure }
        status("Benchmark started: \(seconds) seconds, \(width)x\(height), \(representation.rawValue). Output: \(outputURL?.path ?? "stdout").")
        let samples = TimingSamples()
        let inFlight = DispatchSemaphore(value: 3)
        let completions = DispatchGroup()
        let start = ProcessInfo.processInfo.systemUptime
        let thermalStart = ProcessInfo.processInfo.thermalState.rawValue
        var previous = start, next = start, nextProgress = start+10
        var clock = FixedStepClock(), submitted = 0, dropped = 0
        var intervals: [Double] = []
        var cpuTimes: [Double] = []
        intervals.reserveCapacity(Int(seconds*60)+1); cpuTimes.reserveCapacity(Int(seconds*60)+1)
        while ProcessInfo.processInfo.systemUptime - start < seconds {
            let now = ProcessInfo.processInfo.systemUptime
            if now >= nextProgress {
                status("Benchmark elapsed \(Int(now-start)) / \(Int(seconds)) seconds; \(submitted) frames submitted.")
                nextProgress = now+10
            }
            if now < next { try await Task.sleep(for: .seconds(next-now)); continue }
            next += 1.0/60
            if next < now-0.25 { next = now }
            guard tryAcquire(inFlight) else { dropped += 1; continue }
            try autoreleasepool {
                let began = ProcessInfo.processInfo.systemUptime
                let command = try require(gpu.queue.makeCommandBuffer())
                let steps = clock.consume(elapsed: now-previous)
                intervals.append(now-previous); previous = now
                try gpu.encode(into: command, steps: steps, ribbonFrames: ribbonFrames)
                try renderer.encode(into: command, pass: pass, gpu: gpu, camera: preset.camera, appearance: appearance,
                                    size: SIMD2(Float(width), Float(height)))
                completions.enter()
                command.addCompletedHandler { buffer in
                    samples.record(gpu: buffer.gpuEndTime-buffer.gpuStartTime, failed: buffer.status != .completed)
                    inFlight.signal()
                    completions.leave()
                }
                command.commit()
                cpuTimes.append(ProcessInfo.processInfo.systemUptime-began)
                submitted += 1
            }
        }
        // One end-of-run wait, never a per-frame wait.
        let finish = try require(gpu.queue.makeCommandBuffer())
        await complete(finish)
        await withCheckedContinuation { continuation in
            completions.notify(queue: .global()) { continuation.resume() }
        }
        guard finish.status == .completed else { throw finish.error ?? LorenzError.resourceFailure }
        let elapsed = ProcessInfo.processInfo.systemUptime-start
        let states = try gpu.readback()
        let measured = samples.snapshot()
        #if DEBUG
        let buildConfiguration = "Debug"
        #else
        let buildConfiguration = "Release"
        #endif
        let report: [String: Any] = [
            "device": device.name, "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "buildConfiguration": buildConfiguration,
            "physicalMemoryBytes": ProcessInfo.processInfo.physicalMemory,
            "lowPowerMode": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "thermalStateAtStart": thermalStart, "thermalStateAtEnd": ProcessInfo.processInfo.thermalState.rawValue,
            "preset": preset.rawValue, "resolutionPixels": [width,height], "sampleCount": 1,
            "representation": representation.rawValue,
            "fadeDelay": appearance.fade.delay, "fadeDuration": appearance.fade.duration,
            "ribbonWidthWorldUnits": appearance.ribbonWidth,
            "visibleSegmentsPerTrajectory": appearance.fade.visibleSegments(historyLength: gpu.configuration.trailLength),
            "trajectories": gpu.configuration.trajectoryCount, "trailLength": gpu.configuration.trailLength,
            "sigma": gpu.configuration.parameters.sigma, "rho": gpu.configuration.parameters.rho,
            "beta": gpu.configuration.parameters.beta, "seed": gpu.configuration.seed,
            "fixedTimestep": LorenzConfiguration.timestep, "simulationSpeed": 1,
            "durationSeconds": elapsed, "framesSubmitted": submitted, "completedFrames": measured.2,
            "completedFPS": Double(measured.2)/elapsed, "submissionDrops": dropped,
            "frameIntervalMS": summary(intervals), "cpuEncodeMS": summary(cpuTimes), "gpuCommandMS": summary(measured.0),
            "gpuFailures": measured.1, "trajectoryRestarts": states.reduce(0) { $0+Int($1.restarts) },
            "gpuTimingAvailable": !measured.0.isEmpty,
            "metalAllocatedBytesAtEnd": device.currentAllocatedSize,
            "historyBytes": gpu.configuration.historyBytes, "discardedSimulationTime": clock.discardedTime,
            "note": "Offscreen paced compute+graphics, no window/compositor. Use Instruments for process memory and UI timings."
        ]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        if let outputURL {
            try data.write(to: outputURL, options: .atomic)
            status("JSON written: \(outputURL.path)")
        }
        print(String(decoding: data, as: UTF8.self))
        guard measured.1 == 0, states.allSatisfy({ $0.restarts == 0 }) else { throw ValidationError.gpuFailure }
    }
    static func status(_ message: String) {
        FileHandle.standardError.write(Data((message+"\n").utf8))
    }
    static func require<T>(_ value: T?) throws -> T {
        guard let value else { throw LorenzError.resourceFailure }; return value
    }
    static func tryAcquire(_ gate: DispatchSemaphore) -> Bool { gate.wait(timeout: .now()) == .success }
    @MainActor static func complete(_ command: any MTLCommandBuffer) async {
        await withCheckedContinuation { continuation in
            command.addCompletedHandler { _ in continuation.resume() }
            command.commit()
        }
    }
    static func summary(_ values: [Double]) -> [String: Double] {
        let sorted = values.filter { $0.isFinite && $0 >= 0 }.sorted()
        guard !sorted.isEmpty else { return [:] }
        func percentile(_ p: Double) -> Double { sorted[min(sorted.count-1, Int(Double(sorted.count-1)*p))]*1000 }
        return ["median": percentile(0.5), "p95": percentile(0.95), "p99": percentile(0.99)]
    }
    enum ValidationError: LocalizedError {
        case referenceMismatch, gpuFailure
        var errorDescription: String? { "Lorenz GPU validation failed: \(self)." }
    }
}

private final class TimingSamples: @unchecked Sendable {
    private let lock = NSLock()
    private var gpuTimes: [Double] = []
    private var failures = 0
    private var completed = 0
    func record(gpu: Double, failed: Bool) {
        lock.lock(); defer { lock.unlock() }
        completed += 1
        if gpu > 0, gpu.isFinite { gpuTimes.append(gpu) }
        if failed { failures += 1 }
    }
    func snapshot() -> ([Double], Int, Int) {
        lock.lock(); defer { lock.unlock() }; return (gpuTimes, failures, completed)
    }
}
