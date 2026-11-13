import MetalKit
import SwiftUI
import SurfaceMetal
import WorkspaceCore

struct SurfaceViewport: NSViewRepresentable {
    var session: SurfaceSession
    var revision: UInt64
    var geodesic: (any SurfaceMotionSession)? = nil
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> CameraMetalView {
        let view = CameraMetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.clearDepth = 1
        view.clearColor = MTLClearColor(red: 0.002428, green: 0.002732, blue: 0.003347, alpha: 1)
        view.isPaused = true; view.enableSetNeedsDisplay = true; view.framebufferOnly = true
        view.setAccessibilityLabel("Parametric surface viewport")
        view.setAccessibilityIdentifier("surfaceViewport")
        view.setAccessibilityHelp("Drag or use arrow keys to orbit. Shift-drag to pan. Scroll, pinch, plus or minus to zoom.")
        do {
            guard let device = view.device else { throw SurfaceError.metalUnavailable }
            let renderer = try SurfaceViewRenderer(device: device, session: session, geodesic: geodesic)
            context.coordinator.renderer = renderer; view.delegate = renderer
            renderer.update(view)
            view.interaction = { [weak session, weak view] action in
                guard let session else { return }
                switch action {
                case let .orbit(x,y): session.camera.orbit(x: x,y: y)
                case let .pan(x,y): session.camera.translate(x: x,y: y,viewportHeight: Double(view?.bounds.height ?? 1))
                case let .zoom(amount): session.camera.zoom(amount, minimumDistance: geodesic == nil ? 35 : 1)
                }
                view?.needsDisplay = true
            }
        } catch {
            let message = error.localizedDescription
            Task { @MainActor in session.failure = message }
        }
        return view
    }
    func updateNSView(_ view: CameraMetalView, context: Context) { context.coordinator.renderer?.update(view) }
    final class Coordinator { var renderer: SurfaceViewRenderer? }
}

@MainActor
final class SurfaceViewRenderer: NSObject, MTKViewDelegate {
    private let session: SurfaceSession
    private let renderer: SurfaceRenderer
    private let geodesic: (any SurfaceMotionSession)?
    private let trails: GeodesicTrails?
    private var lastTime: Double?
    private var wasPaused = true
    private var lastRestart: UInt64 = .max
    private var nextSlot = 0
    private var reportTime = 0.0
    private let inFlight = DispatchSemaphore(value: 3)
    private weak var pendingView: MTKView?
    init(device: any MTLDevice, session: SurfaceSession, geodesic: (any SurfaceMotionSession)?) throws {
        self.session = session; self.geodesic = geodesic
        renderer = try SurfaceRenderer(device: device)
        trails = try geodesic.map { _ in try GeodesicTrails(device: device,maximumTracks: geodesic?.maximumRenderTracks ?? 1) }
    }
    func update(_ view: MTKView) {
        let paused = geodesic?.isPaused ?? true
        if paused != wasPaused || lastRestart != (geodesic?.restartID ?? .max) {
            lastTime = nil; wasPaused = paused; lastRestart = geodesic?.restartID ?? .max
        }
        view.preferredFramesPerSecond = 60
        view.isPaused = paused; view.enableSetNeedsDisplay = paused
        view.needsDisplay = true
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { view.needsDisplay = true }
    func draw(in view: MTKView) {
        guard session.failure == nil else { view.isPaused = true; return }
        if geodesic != nil, view.window?.isVisible != true || view.window?.isMiniaturized == true { lastTime = nil; return }
        guard inFlight.wait(timeout: .now()) == .success else {
            // Static/on-demand scenes must retry the latest edit after saturation.
            pendingView = view
            return
        }
        guard let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable else { inFlight.signal(); lastTime = nil; return }
        do {
            if let geodesic {
                let now = ProcessInfo.processInfo.systemUptime
                try geodesic.advance(elapsed: lastTime.map { max(0,now-$0) } ?? 0)
                lastTime = now
                if now-reportTime >= 1 { geodesic.updateDiagnostics(); reportTime = now }
                pass.depthAttachment.storeAction = .store
            }
            let camera = geodesic?.cameraForFrame() ?? session.camera
            geodesic?.recordAnnotationCamera(camera)
            guard let command = renderer.queue.makeCommandBuffer() else { throw SurfaceError.resourceFailure }
            let size = SIMD2(Float(view.drawableSize.width),Float(view.drawableSize.height))
            if let geometry = geodesic?.ellisGeometry, let appearance = geodesic?.ellisAppearance {
                try renderer.encode(into: command,pass: pass,ellis: geometry,appearance: appearance,camera: camera,
                                    surfaceDensity: session.surfaceDensity,grid: session.grid,size: size)
            } else {
                try renderer.encode(into: command,pass: pass,parameters: session.parameters,camera: camera,style: session.style,
                                    surfaceDensity: session.surfaceDensity,grid: session.grid,size: size)
            }
            if let geodesic, let trails {
                pass.colorAttachments[0].loadAction = .load; pass.depthAttachment.loadAction = .load
                let scale = Float(view.drawableSize.height/max(1,view.bounds.height))
                if let tracks = geodesic.renderBatch {
                    if !tracks.isEmpty {
                        try trails.encodeBatch(into: command,pass: pass,tracks: tracks,fade: geodesic.fade,camera: camera,size: size,slot: nextSlot,
                                               pixelScale: scale,depthTolerance: geodesic.depthTolerance)
                    }
                } else {
                    try trails.encode(into: command,pass: pass,trail: geodesic.renderedTrail,fade: geodesic.fade,camera: camera,size: size,slot: nextSlot,
                                      appearance: geodesic.appearance,pixelScale: scale,displayedParticle: geodesic.displayedParticle,depthTolerance: geodesic.depthTolerance)
                }
            }
            command.present(drawable)
            let gate = inFlight
            command.addCompletedHandler { [weak self] buffer in
                gate.signal()
                let message = buffer.status == .error ? buffer.error?.localizedDescription ?? "Metal surface command failed." : nil
                Task { @MainActor [weak self] in
                    if let message { self?.session.failure = message; self?.geodesic?.isPaused = true }
                    self?.pendingView?.needsDisplay = true
                    self?.pendingView = nil
                }
            }
            command.commit(); nextSlot = (nextSlot+1)%3
        } catch {
            inFlight.signal(); session.failure = error.localizedDescription
            geodesic?.isPaused = true; view.isPaused = true
        }
    }
}

struct SurfaceAxisLabels: View {
    var camera: OrbitCamera
    var body: some View {
        GeometryReader { geometry in
            let matrix = CameraProjection.matrix(camera: camera, aspect: Float(geometry.size.width/max(1,geometry.size.height)))
            ForEach(0..<3, id: \.self) { axis in
                let point = axis == 0 ? SIMD4<Float>(15.6,0,0,1) : (axis == 1 ? SIMD4<Float>(0,15.6,0,1) : SIMD4<Float>(0,0,15.6,1))
                let clip = matrix*point
                if clip.w > 0.1, clip.z > 0, clip.z < clip.w, abs(clip.x) < clip.w, abs(clip.y) < clip.w {
                    Text(["x", "y", "z"][axis]).font(Design.numeric).foregroundStyle(Design.secondary)
                        .position(x: CGFloat(clip.x/clip.w+1)*geometry.size.width/2,
                                  y: CGFloat(1-clip.y/clip.w)*geometry.size.height/2)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}


// Only this small child observes the per-frame camera snapshot. Inspector/workspace
// state remains observation-ignored during integration, as before.
struct GeodesicAxisLabels: View {
    var session: any SurfaceMotionSession
    var body: some View { SurfaceAxisLabels(camera: session.annotationCamera) }
}
