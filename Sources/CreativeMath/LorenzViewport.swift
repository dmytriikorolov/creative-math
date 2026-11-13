import MetalKit
import SwiftUI
import LorenzMetal
import WorkspaceCore

struct LorenzViewport: NSViewRepresentable {
    var session: LorenzSession
    var revision: UInt64

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> CameraMetalView {
        let view = CameraMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColor(red: 0.002428, green: 0.002732, blue: 0.003347, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = true
        view.framebufferOnly = true
        view.isPaused = session.isPaused
        view.setAccessibilityLabel("Lorenz attractor viewport")
        view.setAccessibilityIdentifier("lorenzViewport")
        view.setAccessibilityHelp("Drag to orbit. Shift-drag or right-drag to pan. Scroll or pinch to zoom. Arrow keys orbit; plus and minus zoom.")
        do {
            guard let device = view.device else { throw LorenzError.metalUnavailable }
            let renderer = try LorenzRenderer(device: device, session: session)
            Task { @MainActor in session.failure = nil }
            context.coordinator.renderer = renderer
            view.delegate = renderer
            view.interaction = { [weak renderer, weak view] action in
                renderer?.interact(action, height: Double(view?.bounds.height ?? 1))
                view?.needsDisplay = true
            }
        } catch {
            view.isPaused = true
            let message = error.localizedDescription
            Task { @MainActor in session.failure = message }
        }
        return view
    }
    func updateNSView(_ view: CameraMetalView, context: Context) {
        context.coordinator.renderer?.update(view, revision: revision)
    }
    final class Coordinator { var renderer: LorenzRenderer? }
}

enum CameraAction { case orbit(Double, Double), pan(Double, Double), zoom(Double) }

final class CameraMetalView: MTKView {
    var interaction: ((CameraAction) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
    override func mouseDragged(with event: NSEvent) {
        interaction?(event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.option)
                     ? .pan(event.deltaX, event.deltaY) : .orbit(event.deltaX, event.deltaY))
    }
    override func rightMouseDragged(with event: NSEvent) { interaction?(.pan(event.deltaX, event.deltaY)) }
    override func otherMouseDragged(with event: NSEvent) { interaction?(.pan(event.deltaX, event.deltaY)) }
    override func scrollWheel(with event: NSEvent) { interaction?(.zoom(-Double(event.scrollingDeltaY) * (event.hasPreciseScrollingDeltas ? 0.008 : 0.06))) }
    override func magnify(with event: NSEvent) { interaction?(.zoom(-Double(event.magnification))) }
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: interaction?(.orbit(-8,0))
        case 124: interaction?(.orbit(8,0))
        case 125: interaction?(.orbit(0,8))
        case 126: interaction?(.orbit(0,-8))
        default:
            if event.characters == "+" || event.characters == "=" { interaction?(.zoom(-0.1)) }
            else if event.characters == "-" { interaction?(.zoom(0.1)) }
            else { super.keyDown(with: event) }
        }
    }
}

@MainActor
final class LorenzRenderer: NSObject, MTKViewDelegate {
    private let session: LorenzSession
    private let gpu: LorenzGPU
    private let trails: LorenzTrails
    private var camera: OrbitCamera
    private var clock = FixedStepClock()
    private let inFlight = DispatchSemaphore(value: 3)
    private var lastTime: Double?
    private var lastReset: UInt64 = .max
    private var lastCameraReset: UInt64 = .max
    private var lastStep: UInt64 = 0
    private var lastRevision: UInt64 = .max
    private var wasPaused: Bool
    private weak var view: MTKView?
    private var failed = false
    private var reportTime = 0.0
    private var cpuTotal = 0.0, gpuTotal = 0.0
    private var sampleCount = 0, gpuSampleCount = 0
    private var reportFrames = 0

    init(device: any MTLDevice, session: LorenzSession) throws {
        self.session = session
        gpu = try LorenzGPU(device: device, configuration: session.configuration)
        trails = try LorenzTrails(gpu: gpu)
        camera = session.preset.camera
        wasPaused = session.isPaused
        super.init()
    }
    func update(_ view: MTKView, revision: UInt64) {
        self.view = view
        guard revision != lastRevision else { return }
        lastRevision = revision
        if wasPaused != session.isPaused {
            lastTime = nil; wasPaused = session.isPaused
            reportTime = 0; reportFrames = 0; cpuTotal = 0; gpuTotal = 0; sampleCount = 0; gpuSampleCount = 0
        }
        view.isPaused = session.isPaused || failed
        view.needsDisplay = true
    }
    func interact(_ action: CameraAction, height: Double) {
        switch action {
        case let .orbit(x,y): camera.orbit(x: x, y: y)
        case let .pan(x,y): camera.translate(x: x, y: y, viewportHeight: height)
        case let .zoom(amount): camera.zoom(amount)
        }
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { view.needsDisplay = true }
    func draw(in view: MTKView) {
        guard !failed else { return }
        guard view.window?.isVisible == true, view.window?.isMiniaturized == false else { lastTime = nil; return }
        guard inFlight.wait(timeout: .now()) == .success else { return }
        guard let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else {
            inFlight.signal(); lastTime = nil; return
        }
        let began = ProcessInfo.processInfo.systemUptime
        do {
            let structural = gpu.configuration.trajectoryCount != session.configuration.trajectoryCount ||
                gpu.configuration.trailLength != session.configuration.trailLength || gpu.configuration.seed != session.configuration.seed
            try gpu.configure(session.configuration)
            let modeChanged = gpu.tracksRibbonFrames != (session.appearance.representation == .ribbon)
            let resetting = session.resetID != lastReset || structural || modeChanged
            if resetting { clock.reset(); lastTime = nil; lastReset = session.resetID }
            if session.cameraResetID != lastCameraReset { camera = session.preset.camera; lastCameraReset = session.cameraResetID }
            let elapsed = lastTime.map { max(0, began - $0) } ?? 0
            lastTime = began
            var steps = clock.consume(elapsed: elapsed, speed: session.speed, paused: session.isPaused)
            if session.isPaused && session.stepID != lastStep { steps = Int(min(64, session.stepID &- lastStep)) }
            lastStep = session.stepID
            guard let command = gpu.queue.makeCommandBuffer() else { throw LorenzError.resourceFailure }
            try gpu.encode(into: command, steps: steps, reset: resetting, preRoll: true, ribbonFrames: session.appearance.representation == .ribbon)
            try trails.encode(into: command, pass: pass, gpu: gpu, camera: camera, appearance: session.appearance,
                              size: SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height)))
            command.present(drawable)
            let cpuTime = ProcessInfo.processInfo.systemUptime-began
            let gate = inFlight
            command.addCompletedHandler { [weak self] buffer in
                gate.signal()
                let duration = buffer.gpuEndTime-buffer.gpuStartTime
                let failure = buffer.status == .error ? buffer.error?.localizedDescription ?? "Metal command failed." : nil
                Task { @MainActor [weak self] in
                    self?.record(cpu: cpuTime, gpu: duration, failure: failure)
                }
            }
            command.commit()
        } catch {
            inFlight.signal(); failed = true; view.isPaused = true
            session.failure = error.localizedDescription
        }
    }
    private func record(cpu: Double, gpu: Double, failure: String?) {
        if let failure { session.failure = failure; failed = true; view?.isPaused = true; return }
        guard !session.isPaused else { return }
        cpuTotal += cpu; sampleCount += 1; reportFrames += 1
        if gpu > 0, gpu.isFinite { gpuTotal += gpu; gpuSampleCount += 1 }
        let now = ProcessInfo.processInfo.systemUptime
        if reportTime == 0 { reportTime = now }
        if now-reportTime >= 1 {
            let gpuText = gpuSampleCount > 0 ? String(format: "%.2f", gpuTotal/Double(gpuSampleCount)*1000) : "n/a"
            session.timing = String(format: "Completed %.0f/s\nCPU encode %.2f ms · GPU %@ ms", Double(reportFrames)/(now-reportTime), cpuTotal/Double(max(1,sampleCount))*1000, gpuText)
            reportTime = now; reportFrames = 0; cpuTotal = 0; gpuTotal = 0; sampleCount = 0; gpuSampleCount = 0
        }
    }
}
