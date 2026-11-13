import Metal
import simd
import WorkspaceCore

private struct GeodesicUniforms {
    var matrix: simd_float4x4
    var viewport: SIMD4<Float>
    var config: SIMD4<UInt32>
    var fading: SIMD4<Float>
    var depthTolerance: SIMD4<Float>
    var ink: SIMD4<Float>
    var markerInk: SIMD4<Float>
    var ball: SIMD4<Float>
}

// Three persistent upload slots. Caller submits on the surface queue with at most three
// commands in flight and rotates slots only after successful encoding/commit.
@MainActor
public final class GeodesicTrails {
    private let pipeline: any MTLRenderPipelineState
    private let markerPipeline: any MTLRenderPipelineState
    private let depth: any MTLDepthStencilState
    private let buffers: [any MTLBuffer]
    private let maximumTracks: Int
    public init(device: any MTLDevice, maximumTracks: Int = 1) throws {
        guard (1...17).contains(maximumTracks) else { throw SurfaceError.invalidParameters }
        self.maximumTracks = maximumTracks
        let library = try device.makeLibrary(source: geodesicShaderSource,options: nil)
        func make(_ vertex: String, _ fragment: String) throws -> any MTLRenderPipelineState {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: vertex)
            descriptor.fragmentFunction = library.makeFunction(name: fragment)
            descriptor.depthAttachmentPixelFormat = .depth32Float
            let color = descriptor.colorAttachments[0]!
            color.pixelFormat = .bgra8Unorm_srgb; color.isBlendingEnabled = true
            color.sourceRGBBlendFactor = .one; color.destinationRGBBlendFactor = .oneMinusSourceAlpha
            color.sourceAlphaBlendFactor = .one; color.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            return try device.makeRenderPipelineState(descriptor: descriptor)
        }
        pipeline = try make("geodesicVertex","geodesicFragment")
        markerPipeline = try make("geodesicMarker","geodesicMarkerFragment")
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .lessEqual; descriptor.isDepthWriteEnabled = false
        guard let depth = device.makeDepthStencilState(descriptor: descriptor) else { throw SurfaceError.resourceFailure }
        self.depth = depth
        var uploads: [any MTLBuffer] = []
        for slot in 0..<3 {
            guard let buffer = device.makeBuffer(length: maximumTracks*8192*MemoryLayout<SIMD4<Float>>.stride,options: .storageModeShared) else { throw SurfaceError.resourceFailure }
            buffer.label = "Geodesic trail upload \(slot)"; uploads.append(buffer)
        }
        buffers = uploads
    }
    public func encode(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor,
                       trail: GeodesicTrail, fade: TrailFade, camera: OrbitCamera, size: SIMD2<Float>, slot: Int, appearance: GeodesicAppearance = GeodesicAppearance(), pixelScale: Float = 1, displayedParticle: SIMD3<Double>? = nil, depthTolerance: Float = 0.005) throws {
        try encodeBatch(into: command,pass: pass,tracks: [GeodesicRenderTrack(trail: trail,particle: displayedParticle,appearance: appearance)],fade: fade,
                        camera: camera,size: size,slot: slot,pixelScale: pixelScale,depthTolerance: depthTolerance)
    }
    public func encodeBatch(into command: any MTLCommandBuffer, pass: MTLRenderPassDescriptor, tracks: [GeodesicRenderTrack],
                            fade: TrailFade, camera: OrbitCamera, size: SIMD2<Float>, slot: Int, pixelScale: Float = 1, depthTolerance: Float = 0.005) throws {
        guard !tracks.isEmpty, tracks.count <= maximumTracks, depthTolerance.isFinite, (0...0.05).contains(depthTolerance),
              pixelScale.isFinite, (0.5...4).contains(pixelScale), (0..<3).contains(slot), fade.isValid, size.x > 0, size.y > 0,
              tracks.allSatisfy({ $0.appearance.isValid && $0.trail.count > 0 && ($0.ballNormal.map { abs(simd_length($0)-1) < 1e-6 } ?? true) }) else { throw SurfaceError.invalidParameters }
        guard let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { throw SurfaceError.resourceFailure }
        encoder.label = "Spatial geodesic comparison"
        encoder.setCullMode(.none); encoder.setDepthStencilState(depth); encoder.setDepthBias(-1,slopeScale: 0,clamp: 0)
        for (index,track) in tracks.enumerated() {
            let appearance = track.appearance, trail = track.trail
            if !appearance.particleVisible && !appearance.trailVisible { continue }
            let offset = index*8192*MemoryLayout<SIMD4<Float>>.stride
            let destination = buffers[slot].contents().advanced(by: offset)
            trail.points.withUnsafeBytes { destination.copyMemory(from: $0.baseAddress!,byteCount: $0.count) }
            if let particle = track.particle { destination.bindMemory(to: SIMD4<Float>.self,capacity: 8192)[trail.head] = SIMD4(SIMD3<Float>(particle),0) }
            let standard = track.color == SIMD4<Float>(0.88,0.55,0.20,1)
            let marker = standard ? SIMD4<Float>(1,0.83,0.48,1) : SIMD4(SIMD3(track.color.x,track.color.y,track.color.z)*0.65+SIMD3<Float>(repeating: 0.35),track.color.w)
            let matrix = CameraProjection.matrix(camera: camera,aspect: size.x/size.y)
            let point = track.particle ?? SIMD3<Double>(SIMD3<Float>(trail.points[trail.head].x,trail.points[trail.head].y,trail.points[trail.head].z))
            let clip = matrix*SIMD4(SIMD3<Float>(point),1)
            // Center the visual sphere on the same point as its trail head.
            // Radius affects shading/depth, never the geodesic or trail position.
            let radius = Float(appearance.particleDiameterPoints)*pixelScale*max(0,clip.w)*tan(Float(0.35))/size.y
            let ball = SIMD4<Float>(0,0,0,track.ballNormal == nil ? 0 : radius)
            var uniforms = GeodesicUniforms(matrix: matrix,
                viewport: SIMD4(size.x,size.y,Float(appearance.trailWidthPoints)*pixelScale,Float(appearance.particleDiameterPoints)*pixelScale/2),
                config: SIMD4(UInt32(trail.head),UInt32(trail.count),UInt32(trail.points.count),UInt32(fade.visibleSegments(historyLength: trail.points.count))),
                fading: SIMD4(Float(FixedStepClock.timestep),Float(fade.delay),Float(fade.duration),CameraProjection.near*CameraProjection.far/(CameraProjection.far-CameraProjection.near)),
                depthTolerance: SIMD4(depthTolerance,CameraProjection.far/(CameraProjection.far-CameraProjection.near),0,0),ink: track.color,markerInk: marker,ball: ball)
            encoder.setVertexBytes(&uniforms,length: MemoryLayout<GeodesicUniforms>.stride,index: 1)
            encoder.setFragmentBytes(&uniforms,length: MemoryLayout<GeodesicUniforms>.stride,index: 1)
            encoder.setDepthBias(-1,slopeScale: 0,clamp: 0)
            encoder.setVertexBuffer(buffers[slot],offset: offset,index: 0)
            encoder.setRenderPipelineState(pipeline)
            let visible = min(trail.count-1,Int(uniforms.config.w))
            if visible > 0 && appearance.trailVisible { encoder.drawPrimitives(type: .triangle,vertexStart: 0,vertexCount: visible*6) }
            if appearance.particleVisible {
                if track.ballNormal != nil { encoder.setDepthBias(0,slopeScale: 0,clamp: 0) }
                encoder.setRenderPipelineState(markerPipeline); encoder.drawPrimitives(type: .triangle,vertexStart: 0,vertexCount: 6)
            }
        }
        encoder.endEncoding()
    }

}

private let geodesicShaderSource = """
#include <metal_stdlib>
using namespace metal;
struct Uniforms { float4x4 matrix; float4 viewport; uint4 config; float4 fading; float4 depthTolerance; float4 ink; float4 markerInk; float4 ball; };
struct Out { float4 position [[position]]; float2 edge; float alpha; float4 color; float2 sphere; };
// Analytic torus samples can sit slightly behind the faceted mesh, especially on
// the inner equator. Move raster depth toward the eye by 0.005 world units; unlike
// a fixed depth-buffer bias, this tolerance remains useful during close inspection.
float4 surfaceDepth(float4 p, constant Uniforms &u) {
    p.z -= u.fading.w*u.depthTolerance.x/max(p.w-u.depthTolerance.x,0.01f);
    return p;
}
float ageFade(float age, constant Uniforms &u) {
    float alpha = age <= u.fading.y ? 1.0f : (u.fading.z <= 0 ? 0.0f : 1.0f-smoothstep(0.0f,1.0f,(age-u.fading.y)/u.fading.z));
    float capacity = float(u.config.z-1)*u.fading.x;
    return alpha*smoothstep(0.0f,min(0.25f,capacity*0.25f),capacity-age);
}
vertex Out geodesicVertex(uint id [[vertex_id]], device const float4 *points [[buffer(0)]], constant Uniforms &u [[buffer(1)]]) {
    Out out; out.position = float4(2,2,2,1); out.edge = float2(0); out.alpha = 0; out.color = u.ink; out.sphere = float2(0);
    uint visible = min(u.config.y-1,u.config.w);
    uint logical = u.config.y-1-visible+id/6, corner = id%6;
    uint oldest = (u.config.x+u.config.z+1-u.config.y)%u.config.z;
    float4 a = u.matrix*float4(points[(oldest+logical)%u.config.z].xyz,1);
    float4 b = u.matrix*float4(points[(oldest+logical+1)%u.config.z].xyz,1);
    if (min(a.w,b.w) <= 0.1f) return out;
    float2 delta = (b.xy/b.w-a.xy/a.w)*u.viewport.xy;
    float squareLength = dot(delta,delta);
    if (squareLength < 1e-8f) return out;
    const uint ends[6] = {0,1,0,0,1,1};
    const float signs[6] = {-1,-1,1,1,-1,1};
    float4 p = ends[corner] ? b : a;
    float2 side = float2(-delta.y,delta.x)*rsqrt(squareLength);
    p.xy += side*signs[corner]*(u.viewport.z*0.5f+0.75f)*2.0f/u.viewport.xy*p.w;
    out.position = surfaceDepth(p,u); out.edge = float2(signs[corner],0);
    out.alpha = ageFade(float(u.config.y-1-logical-ends[corner])*u.fading.x,u);
    return out;
}
fragment float4 geodesicFragment(Out in [[stage_in]]) {
    float alpha = in.alpha*(1.0f-smoothstep(0.35f,1.0f,abs(in.edge.x)))*0.92f;
    alpha *= in.color.a; return float4(in.color.rgb*alpha,alpha);
}
vertex Out geodesicMarker(uint id [[vertex_id]], device const float4 *points [[buffer(0)]], constant Uniforms &u [[buffer(1)]]) {
    const float2 corners[6] = {float2(-1,-1),float2(1,-1),float2(-1,1),float2(-1,1),float2(1,-1),float2(1,1)};
    Out out; out.position = u.matrix*float4(points[u.config.x].xyz+u.ball.xyz,1); out.edge = corners[id]; out.alpha = 1; out.color = u.markerInk; out.sphere = float2(out.position.w,u.ball.w);
    if (out.position.w <= 0.1f) { out.position = float4(2,2,2,1); return out; }
    out.position.xy += out.edge*u.viewport.w*2.0f/u.viewport.xy*out.position.w;
    if (u.ball.w == 0) out.position = surfaceDepth(out.position,u);
    return out;
}
struct MarkerOut { float4 color [[color(0)]]; float depth [[depth(any)]]; };
fragment MarkerOut geodesicMarkerFragment(Out in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    float r2 = dot(in.edge,in.edge);
    if (r2 >= 1) discard_fragment();
    MarkerOut out;
    float alpha = (1.0f-smoothstep(0.70f,1.0f,sqrt(r2)))*in.color.a;
    float3 color = in.color.rgb;
    out.depth = in.position.z;
    if (in.sphere.y > 0) {
        float z = sqrt(max(0.0f,1.0f-r2));
        float3 normal = float3(in.edge,z);
        float diffuse = max(0.0f,dot(normal,normalize(float3(-0.45f,0.6f,1.0f))));
        float highlight = pow(max(0.0f,dot(normal,normalize(float3(-0.3f,0.4f,1.0f)))),32.0f);
        color = color*(0.25f+0.7f*diffuse)+float3(0.3f)*highlight;
        alpha = (1.0f-smoothstep(1.0f-fwidth(r2),1.0f,r2))*in.color.a;
        // Sphere-front depth preserves sheet occlusion without slicing a flat disc.
        float eyeDepth = max(0.1f,in.sphere.x-in.sphere.y*z);
        out.depth = u.depthTolerance.y-u.fading.w/eyeDepth;
    }
    out.color = float4(color*alpha,alpha);
    return out;
}
"""
