let surfaceShaderSource = """
#include <metal_stdlib>
using namespace metal;
struct Vertex { float4 point; float4 normal; float4 uv; };
struct Uniforms { float4x4 matrix; float4 eye; float4 style; float4 viewport; float4 grid; };
struct Out { float4 position [[position]]; float3 normal; float3 toEye; float3 uv; float3 world; };
vertex Out surfaceVertex(uint id [[vertex_id]], device const Vertex *vertices [[buffer(0)]], constant Uniforms &u [[buffer(1)]]) {
    Vertex v = vertices[id];
    Out out;
    out.position = u.matrix*v.point; out.normal = v.normal.xyz;
    out.toEye = u.eye.xyz-v.point.xyz; out.uv = v.uv.xyz; out.world = v.point.xyz;
    return out;
}
fragment float4 surfaceFragment(Out in [[stage_in]], constant Uniforms &u [[buffer(1)]]) {
    if (u.grid.y > 0 && max(abs(in.world.x),abs(in.world.z)) > u.grid.y) discard_fragment();
    float2 grid = u.grid.x > 0 ? in.world.xz/u.grid.x : in.uv.xy*u.style.xy;
    // The angle is evaluated in Double at mesh vertices. Interpolating that
    // coordinate avoids asin amplifying Float position error at the tangent.
    if (u.grid.w > 0 && in.world.x > u.grid.z) {
        grid.x = (u.grid.z+u.grid.w*in.uv.z)/u.grid.x;
    }
    float2 footprint = max(fwidth(grid),float2(1e-5f));
    float2 distanceToLine = abs(fract(grid+0.5f)-0.5f)/footprint;
    float2 lines = 1.0f-smoothstep(float2(0.35f),float2(1.15f),distanceToLine);
    // Attenuate unresolved cells instead of letting distant grids form moire.
    lines *= 1.0f-smoothstep(float2(0.35f),float2(1.0f),footprint);
    float coverage = max(lines.x,lines.y)*u.viewport.z;
    float3 n = normalize(in.normal), view = normalize(in.toEye);
    float light = 0.28f+0.52f*abs(dot(n,normalize(float3(-0.3f,0.8f,0.5f))));
    float facing = abs(dot(n,view));
    float3 ink = mix(float3(0.22f,0.32f,0.36f),float3(0.55f,0.68f,0.70f),0.35f+0.65f*facing);
    float3 canvas = float3(0.002428f,0.002732f,0.003347f);
    float3 base = u.style.z > 0.5f ? float3(0.07f,0.10f,0.115f)*light : canvas;
    return float4(mix(base,ink,coverage*0.88f)*u.style.w,u.style.w);
}
struct GridVertex { float4 point; float4 color; };
struct GridOut { float4 position [[position]]; float4 color; float edge; };
vertex GridOut coordinateVertex(uint id [[vertex_id]], device const GridVertex *points [[buffer(0)]], constant Uniforms &u [[buffer(1)]]) {
    uint segment = id/6, corner = id%6;
    GridVertex a = points[segment*2], b = points[segment*2+1];
    float4 ca = u.matrix*a.point, cb = u.matrix*b.point;
    GridOut out; out.position = float4(2,2,2,1); out.color = float4(0); out.edge = 0;
    // Whole-segment rejection: never stretch a quad across the near plane.
    if (min(ca.w,cb.w) <= 0.1f) return out;
    float2 delta = (cb.xy/cb.w-ca.xy/ca.w)*u.viewport.xy;
    float squareLength = dot(delta,delta);
    if (squareLength < 1e-8f) return out;
    float2 side = float2(-delta.y,delta.x)*rsqrt(squareLength);
    const uint ends[6] = {0,1,0,0,1,1};
    const float signs[6] = {-1,-1,1,1,-1,1};
    float4 p = ends[corner] == 0 ? ca : cb;
    p.xy += side*signs[corner]*1.15f*2.0f/u.viewport.xy*p.w;
    out.position = p; out.color = a.color; out.edge = signs[corner];
    return out;
}
fragment float4 coordinateFragment(GridOut in [[stage_in]]) {
    float alpha = (1.0f-smoothstep(0.25f,1.0f,abs(in.edge)))*0.65f;
    return float4(in.color.rgb*alpha,alpha);
}
"""
