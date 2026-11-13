// Shared by the app and the GPU validation executable. Runtime compilation supports CLT builds.
let lorenzShaderSource = """
#include <metal_stdlib>
using namespace metal;
struct State { float4 point; uint4 info; };
struct Simulation { float4 model; uint4 config; uint4 flags; };
float seedCoordinate(uint id, uint seed, uint lane) {
    uint x = seed + id * 747796405u + lane * 2891336453u;
    x = (x ^ (x >> 16)) * 2246822519u;
    x = (x ^ (x >> 13)) * 3266489917u;
    x ^= x >> 16;
    return 1.0f + (float(x & 0x00FFFFFFu) / 16777216.0f - 0.5f) * 0.04f;
}
float3 initialPoint(uint id, uint seed) {
    return float3(seedCoordinate(id, seed, 0), seedCoordinate(id, seed, 1), seedCoordinate(id, seed, 2));
}
float3 derivative(float3 p, float3 m) {
    return float3(m.x*(p.y-p.x), p.x*(m.y-p.z)-p.y, p.x*p.y-m.z*p.z);
}
float3 rk4(float3 p, float4 m) {
    float3 a = derivative(p, m.xyz);
    float3 b = derivative(p + a*(m.w*0.5f), m.xyz);
    float3 c = derivative(p + b*(m.w*0.5f), m.xyz);
    float3 d = derivative(p + c*m.w, m.xyz);
    return p + (a + 2.0f*b + 2.0f*c + d)*(m.w/6.0f);
}
float3 ribbonUnit(float3 v, float3 fallback) {
    float squareLength = dot(v,v);
    return isfinite(squareLength) && squareLength > 1e-16f ? v*rsqrt(squareLength) : fallback;
}
float3 displayVector(float3 p) { return float3(p.x, p.z, -p.y); }
float3 displayPoint(float3 p) { return displayVector(p) - float3(0,25,0); }
float3 ribbonInitialSide(float3 tangent) {
    float3 t = ribbonUnit(tangent, float3(1,0,0));
    float3 a = abs(t);
    float3 axis = a.x <= a.y && a.x <= a.z ? float3(1,0,0) : (a.y <= a.z ? float3(0,1,0) : float3(0,0,1));
    return ribbonUnit(cross(t,axis), float3(0,1,0));
}
float2 ribbonSign(float2 p) { return select(float2(-1),float2(1),p >= 0.0f); }
uint ribbonPack(float3 side) {
    float3 n = ribbonUnit(side, float3(0,1,0));
    float2 p = n.xy/(abs(n.x)+abs(n.y)+abs(n.z));
    if (n.z < 0) p = (1.0f-abs(p.yx))*ribbonSign(p);
    uint2 q = uint2(round(clamp(p*0.5f+0.5f,0.0f,1.0f)*4095.0f));
    return q.x | (q.y << 12);
}
float3 ribbonUnpack(uint packed) {
    float2 p = float2(packed & 4095u, (packed >> 12) & 4095u)/4095.0f*2.0f-1.0f;
    float3 n = float3(p,1.0f-abs(p.x)-abs(p.y));
    if (n.z < 0) n.xy = (1.0f-abs(p.yx))*ribbonSign(p);
    return ribbonUnit(n,float3(0,1,0));
}
float3 ribbonTransport(float3 side, float3 oldTangent, float3 newTangent) {
    float3 a = ribbonUnit(oldTangent,float3(1,0,0));
    float3 b = ribbonUnit(newTangent,a);
    float3 previous = ribbonUnit(side-a*dot(side,a),ribbonInitialSide(a));
    float3 axis = cross(a,b);
    float cosine = clamp(dot(a,b),-1.0f,1.0f);
    float3 result = previous;
    if (cosine > -0.9999f) result += cross(axis,previous)+cross(axis,cross(axis,previous))/(1.0f+cosine);
    result = ribbonUnit(result-b*dot(result,b),ribbonInitialSide(b));
    return dot(result,previous) < 0 ? -result : result;
}
kernel void initializeTrajectories(device State *states [[buffer(0)]], device float4 *history [[buffer(1)]],
                                   constant Simulation &u [[buffer(2)]], uint id [[thread_position_in_grid]]) {
    if (id >= u.config.x) return;
    float3 initial = initialPoint(id,u.config.w);
    uint frame = u.flags.x ? ribbonPack(ribbonInitialSide(displayVector(derivative(initial,u.model.xyz)))) : 0;
    float4 p = float4(initial, float(frame));
    states[id] = { p, uint4(0, 1, 0, 0) };
    history[id*u.config.y] = p;
}
kernel void clearTrails(device State *states [[buffer(0)]], device float4 *history [[buffer(1)]],
                        constant Simulation &u [[buffer(2)]], uint id [[thread_position_in_grid]]) {
    if (id >= u.config.x) return;
    states[id].info.xy = uint2(0, 1);
    float3 tangent = displayVector(derivative(states[id].point.xyz,u.model.xyz));
    float3 side = ribbonUnpack(uint(states[id].point.w));
    float3 t = ribbonUnit(tangent,float3(1,0,0));
    states[id].point.w = u.flags.x ? float(ribbonPack(ribbonUnit(side-t*dot(side,t),ribbonInitialSide(t)))) : 0;
    history[id*u.config.y] = states[id].point;
}
kernel void integrateTrajectories(device State *states [[buffer(0)]], device float4 *history [[buffer(1)]],
                                  constant Simulation &u [[buffer(2)]], uint id [[thread_position_in_grid]]) {
    if (id >= u.config.x) return;
    State s = states[id];
    for (uint step=0; step<u.config.z; ++step) {
        float3 p = rk4(s.point.xyz, u.model);
        uint frame = 0;
        if (!all(isfinite(p)) || any(abs(p) >= 10000.0f)) {
            p = initialPoint(id, u.config.w);
            s.info.x = 0; s.info.y = 1; s.info.z += 1;
            if (u.flags.x) frame = ribbonPack(ribbonInitialSide(displayVector(derivative(p,u.model.xyz))));
        } else {
            s.info.x = (s.info.x + 1) % u.config.y;
            s.info.y = min(s.info.y + 1, u.config.y);
            if (u.flags.x) frame = ribbonPack(ribbonTransport(ribbonUnpack(uint(s.point.w)),
                displayVector(derivative(s.point.xyz,u.model.xyz)),displayVector(derivative(p,u.model.xyz))));
        }
        s.point = float4(p, float(frame));
        history[id*u.config.y + s.info.x] = s.point;
    }
    states[id] = s;
}

struct DrawUniforms {
    float4x4 matrix; float4 viewport; uint4 config; float4 low; float4 high;
    float4 fading; float4 eye;
};
float trailFade(float age, constant DrawUniforms &u) {
    float alpha = age <= u.fading.x ? 1.0f : (u.fading.y <= 0 ? 0.0f : 1.0f-smoothstep(0.0f,1.0f,(age-u.fading.x)/u.fading.y));
    float capacity = float(u.config.y-1)*u.fading.z;
    alpha *= smoothstep(0.0f,min(0.25f,capacity*0.25f),capacity-age);
    return alpha;
}
float3 trailColor(float z, uint id, constant DrawUniforms &u) {
    float height = clamp((z-5.0f)/42.0f,0.0f,1.0f);
    float variation = float(id)/max(float(u.config.x-1),1.0f);
    return mix(u.low.xyz,u.high.xyz,clamp(height*0.8f+variation*0.2f,0.0f,1.0f));
}
struct LineVertexOut { float4 position [[position]]; float4 color; float edge; };
vertex LineVertexOut trailVertex(uint vertexIndex [[vertex_id]], uint id [[instance_id]],
                                 device const State *states [[buffer(0)]], device const float4 *history [[buffer(1)]],
                                 constant DrawUniforms &u [[buffer(2)]]) {
    uint segment = vertexIndex/6, corner = vertexIndex%6;
    uint count = states[id].info.y;
    LineVertexOut out; out.position = float4(2,2,2,1); out.color = float4(0); out.edge = 0;
    if (count < 2) return out;
    uint visible = min(count-1,u.config.z);
    if (segment >= visible) return out;
    uint logical = count-1-visible+segment;
    uint oldest = (states[id].info.x+u.config.y+1-count)%u.config.y;
    float3 a = history[id*u.config.y+(oldest+logical)%u.config.y].xyz;
    float3 b = history[id*u.config.y+(oldest+logical+1)%u.config.y].xyz;
    float4 ca = u.matrix*float4(displayPoint(a),1);
    float4 cb = u.matrix*float4(displayPoint(b),1);
    if (ca.w <= 0.01f || cb.w <= 0.01f) return out;
    float2 direction = (cb.xy/cb.w-ca.xy/ca.w)*u.viewport.xy;
    float magnitude = length(direction);
    if (magnitude < 0.0001f) return out;
    float2 normal = float2(-direction.y,direction.x)/magnitude;
    const uint ends[6] = {0,1,0,0,1,1};
    const float sides[6] = {-1,-1,1,1,-1,1};
    uint endpoint = ends[corner];
    float4 p = endpoint == 0 ? ca : cb;
    float halfWidth = u.viewport.z*0.5f+0.75f;
    p.xy += normal*sides[corner]*halfWidth*2.0f/u.viewport.xy*p.w;
    float age = float(count-1-logical-endpoint)*u.fading.z;
    float alpha = u.viewport.w*trailFade(age,u)*clamp(130.0f/p.w,0.3f,1.0f);
    out.position = p;
    out.color = float4(trailColor(endpoint == 0 ? a.z : b.z,id,u),alpha);
    out.edge = sides[corner];
    return out;
}
fragment float4 trailFragment(LineVertexOut in [[stage_in]]) {
    float alpha = in.color.a*(1.0f-smoothstep(0.35f,1.0f,abs(in.edge)));
    return float4(in.color.rgb*alpha,alpha);
}
struct SculptureVertexOut {
    float4 position [[position]]; float4 color; float3 surfaceNormal; float3 toEye; float edge;
};
vertex SculptureVertexOut sculptureVertex(uint vertexIndex [[vertex_id]], uint id [[instance_id]],
                                           device const State *states [[buffer(0)]], device const float4 *history [[buffer(1)]],
                                           constant DrawUniforms &u [[buffer(2)]]) {
    uint segment = vertexIndex/6, corner = vertexIndex%6;
    uint count = states[id].info.y;
    SculptureVertexOut out;
    out.position = float4(2,2,2,1); out.color = float4(0);
    out.surfaceNormal = float3(0,1,0); out.toEye = float3(0,0,1); out.edge = 0;
    if (count < 2) return out;
    uint visible = min(count-1,u.config.z);
    if (segment >= visible) return out;
    uint logical = count-1-visible+segment;
    uint oldest = (states[id].info.x+u.config.y+1-count)%u.config.y;
    uint base = id*u.config.y;
    float4 a = history[base+(oldest+logical)%u.config.y];
    float4 b = history[base+(oldest+logical+1)%u.config.y];
    // Reject the whole segment if any offset corner could cross the camera near plane.
    // Returning only one endpoint offscreen would create a large spurious triangle.
    float4 depthRow = float4(u.matrix[0].w,u.matrix[1].w,u.matrix[2].w,u.matrix[3].w);
    float nearest = min(dot(depthRow,float4(displayPoint(a.xyz),1)),dot(depthRow,float4(displayPoint(b.xyz),1)));
    if (nearest <= 0.1f+u.fading.w*0.5f) return out;
    float3 delta = displayVector(b.xyz-a.xyz);
    if (dot(delta,delta) < 1e-12f) return out;
    const uint ends[6] = {0,1,0,0,1,1};
    const float sides[6] = {-1,-1,1,1,-1,1};
    uint sampleIndex = logical+ends[corner];
    float4 center = ends[corner] == 0 ? a : b;
    float3 before = history[base+(oldest+(sampleIndex > 0 ? sampleIndex-1 : sampleIndex))%u.config.y].xyz;
    float3 after = history[base+(oldest+min(sampleIndex+1,count-1))%u.config.y].xyz;
    float3 tangent = ribbonUnit(displayVector(after-before),ribbonUnit(delta,float3(1,0,0)));
    float3 side = ribbonUnpack(uint(center.w));
    // Shared endpoint positions avoid miter spikes/cracks; width is in world units, never pixels.
    float3 world = displayPoint(center.xyz)+side*(sides[corner]*u.fading.w*0.5f);
    float4 projected = u.matrix*float4(world,1);
    if (projected.w <= 0.01f) return out;
    float age = float(count-1-sampleIndex)*u.fading.z;
    out.position = projected;
    out.color = float4(trailColor(center.z,id,u),u.viewport.w*trailFade(age,u));
    out.surfaceNormal = ribbonUnit(cross(tangent,side),float3(0,1,0));
    out.toEye = u.eye.xyz-world;
    out.edge = sides[corner];
    return out;
}
fragment float4 sculptureFragment(SculptureVertexOut in [[stage_in]]) {
    float3 n = ribbonUnit(in.surfaceNormal,float3(0,1,0));
    float3 v = ribbonUnit(in.toEye,float3(0,0,1));
    if (dot(n,v) < 0) n = -n;
    float3 light = normalize(float3(-0.4f,0.8f,0.5f));
    float diffuse = 0.22f+0.70f*max(dot(n,light),0.0f);
    float3 halfway = ribbonUnit(light+v,n);
    // Deliberately simple two-sided Blinn-Phong, not a PBR/volumetric material.
    float specular = 0.32f*pow(max(dot(n,halfway),0.0f),32.0f);
    float3 color = in.color.rgb*diffuse+float3(1.0f,0.82f,0.55f)*specular;
    float edge = 1.0f-smoothstep(max(0.0f,1.0f-max(fwidth(in.edge),0.001f)),1.0f,abs(in.edge));
    float alpha = in.color.a*edge;
    return float4(color*alpha,alpha);
}
"""
