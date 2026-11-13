import MetalKit
import SwiftUI
import WorkspaceCore

struct MetalViewport: NSViewRepresentable {
    var scene: WorkspaceScene
    var onFailure: @MainActor (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        // Linear equivalents of the #08090B canvas token for the sRGB attachment.
        view.clearColor = MTLClearColor(red: 0.002428, green: 0.002732, blue: 0.003347, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.framebufferOnly = true
        view.setAccessibilityLabel(scene == .triangle ? "Metal viewport, triangle study" : "Empty Metal viewport")
        do {
            let renderer = try PrimitiveRenderer(view: view, onFailure: onFailure)
            renderer.scene = scene
            context.coordinator.renderer = renderer
            view.delegate = renderer
        } catch {
            let message = error.localizedDescription
            Task { @MainActor in onFailure(message) }
        }
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.scene = scene
        view.setAccessibilityLabel(scene == .triangle ? "Metal viewport, triangle study" : "Empty Metal viewport")
        view.needsDisplay = true
    }

    final class Coordinator {
        var renderer: PrimitiveRenderer?
    }
}

// MTKView draws on the main thread in this on-demand configuration.
@MainActor
final class PrimitiveRenderer: NSObject, MTKViewDelegate {
    var scene: WorkspaceScene = .blank
    private let queue: any MTLCommandQueue
    private let pipeline: any MTLRenderPipelineState
    private let onFailure: @MainActor (String) -> Void

    init(view: MTKView, onFailure: @escaping @MainActor (String) -> Void) throws {
        guard let device = view.device, let queue = device.makeCommandQueue() else {
            throw RenderError.unavailable
        }
        self.queue = queue
        self.onFailure = onFailure
        // Runtime compilation also supports Command Line Tools builds without metal/metallib.
        let library = try device.makeLibrary(source: Self.shader, options: nil)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "primitiveVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "primitiveFragment")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        guard let command = queue.makeCommandBuffer(),
              let encoder = command.makeRenderCommandEncoder(descriptor: descriptor) else {
            onFailure("Metal could not create a render command.")
            return
        }
        if scene == .triangle {
            encoder.setRenderPipelineState(pipeline)
            var aspect = Float(view.drawableSize.width / max(view.drawableSize.height, 1))
            encoder.setVertexBytes(&aspect, length: MemoryLayout<Float>.size, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        }
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }

    enum RenderError: LocalizedError {
        case unavailable
        var errorDescription: String? { "Metal is unavailable on this device." }
    }

    // Coordinates: centered clip space, +Y up; aspect correction keeps shape stable on resize.
    // Fragment output is linear RGB; the sRGB drawable performs display encoding.
    private static let shader = """
    #include <metal_stdlib>
    using namespace metal;
    struct Vertex { float4 position [[position]]; };
    vertex Vertex primitiveVertex(uint id [[vertex_id]], constant float &aspect [[buffer(0)]]) {
        const float2 points[3] = { float2(0, 0.48), float2(-0.42, -0.30), float2(0.42, -0.30) };
        float2 p = points[id];
        p.x /= max(aspect, 0.01f);
        return {float4(p, 0, 1)};
    }
    fragment float4 primitiveFragment() {
        return float4(0.283f, 0.397f, 0.807f, 1.0f);
    }
    """
}
