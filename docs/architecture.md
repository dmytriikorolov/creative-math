# Architecture decisions (initial)

## Stack
Native macOS, Swift 6, SwiftUI for application shell and inspector UI, MTKView/Metal for drawing and compute, Metal Shading Language for shaders. Avoid C++ until a measurable need is demonstrated. Target Apple Silicon; exact deployment target and Xcode version chosen when local environment is inspected.

## Boundaries
- **App/UI:** workspace state, interactions, focus, window management; no numerical solver code.
- **Scene/Document:** typed scene models, versioned persistence, parameters, validation, camera, appearance, animation metadata.
- **Math/Simulation:** pure model functions, integrators, solver step/state; independently unit-testable, with deterministic initial conditions.
- **Render:** scene adapters, GPU resources, compute and graphics pipelines, camera, draw scheduling, export targets. No UI ownership.
- **Export:** offscreen rendering, color management, PNG encoding (V0.1), offline frame sequence + video (V0.2).

Do not split these into packages until real code benefits from the separation.

## Runtime model
UI edits typed parameters → validated scene snapshot → simulation fixed steps (when running) → render snapshot/Metal buffers → display. Render frequency can differ from simulation frequency. Use fixed dt (initial candidate 1/120 s) with bounded catch-up steps; document handling of slow frames. Paused single-step increments one exact simulation step. Offline timeline evaluation uses frame-indexed parameter curves and a defined simulation policy; scrubbing stateful dynamics requires checkpointing/replay, not merely setting wall-clock time.

## Lorenz initial implementation
ODE: dx/dt = σ(y−x); dy/dt = x(ρ−z)−y; dz/dt = xy−βz. Choose and document an integrator (e.g. RK4), timestep, initial condition and floating-point precision. Unit-test derivative and integration against trusted reference trajectories over short horizons. Chaotic long-term trajectories will diverge numerically; never promise bit-identical results across hardware/compiler versions.

## Scene documents
Versioned JSON documents, e.g. `{ "schemaVersion": 1, "scene": { "kind": "attractor", ... } }`; use Codable and explicit schema migration strategy. Persist math model identity and parameters, initial conditions, seed, camera, visual settings, and (when implemented) timeline. Keep transient GPU handles and UI hover state out of documents. Test save/load round trip and invalid/corrupt input handling.

## Expression support (later)
Tokenizer → parser → typed AST → validation (allowlisted operators/functions, bounded complexity, no loops or side effects) → evaluation or constrained codegen. Surface syntax and numerical errors. Do not compile arbitrary untrusted user source into unrestricted shaders.

## Optimization Lab (later)
Model objective f:R^n→R, optional constraints and derivatives; solver interface consumes model/start/config and produces step records (iterate, objective, gradient norm, status). Visualizer maps records to contours, surfaces, vectors, and overlays. For n>2 use explicit 2D slices or projections and label them as such. Start with Rosenbrock + gradient descent + Newton; validate on known convex quadratics too.

## Performance strategy
Budget for M2 Air 8 GB unified memory. Initial target 60 FPS (~16.7 ms/frame), typical scene process memory ≤1 GB, 20-min sustained workload; these are acceptance targets to measure, not guarantees. GPU buffers reused, avoid per-frame allocations and readbacks. Record render scale, particle count, device, OS, power mode and sustained frame times. Dynamic quality must not silently change mathematical state.

## M1 Lorenz implementation

`WorkspaceCore` holds the pure Double reference, validated typed configuration/presets, fixed
clock and camera values. `LorenzMetal` holds Float32 RK4 compute, private ring history and a
trail ribbon pass; both the SwiftUI viewport and a command-line validation tool use this backend.
These are targets in one package, not a general scene engine. The Xcode project mirrors them.

Runtime dt is 1/240 nominal dimensionless Lorenz time units; the GPU stores its Float32 rounding.
The clock caps elapsed wall time at 0.25 s and catches up at most 64 steps per drawable. Excess
simulation time is discarded and reported by the workload tool; dt/precision/trajectory count
never change to catch up. Pause clears the wall-time anchor. Absent/minimized drawables clear
it when observed; unobserved gaps use the same capped catch-up/drop policy. Camera updates
and inspector placement do not reset simulation.

Sculpture maintains a transported spatial side vector in the history point's otherwise unused
fourth Float32 component. It stores two 12-bit octahedral coordinates as a finite, exactly
representable 24-bit integer; no additional history/state buffers are needed. Frame transport
is fused with integration only for the ribbon representation and does not change XYZ RK4.
Switching representation restarts seeded pre-roll; width and fading are draw-only settings.

Classic/Filament use screen-space line quads. Sculpture uses world-space strip endpoints and
simple two-sided directional/Blinn-Phong shading. Both emit two triangles per visible segment;
there is no volume, shadow pass, depth sorting or PBR material. Fade age is an integer sample
distance from the head multiplied by dt. A smoothstep delay/duration curve is multiplied by a
history-boundary taper, independently of wall time. See [refinement record](evidence/m1-refinement.md).

Reset is a deterministic initial-point kernel followed by 2400 + trailLength − 1 actual RK4
steps, in bounded GPU dispatches. Thus the first visible trail covers mathematical times
10 through 10 + (trailLength − 1)/240. This pre-roll is part of scene construction, not fabricated
history. Subsequent fixed-clock time is relative to that reproducible visible starting state.
Model edits preserve current positions and clear history; topology edits restart the seeded
pre-roll. Speed only changes how many fixed steps are due. Details and limits: [M1 record](evidence/m1.md).


## M2 parametric surfaces

The user changed M2 to Geometry & Surfaces on 2026-11-01; document persistence/export
remain deferred. `WorkspaceCore/ParametricSurface.swift` owns validated Double models,
analytic samples/normals, bounded indexed meshes and the coordinate scaffold. No SwiftUI
or Metal enters the model. `SurfaceMetal` is a small renderer target consuming those meshes,
not a scene engine. `SurfaceSession`, `SurfaceViewport` and `SurfaceInspector` own app state,
on-demand rendering, camera input and native controls. Lorenz keeps its existing backend.
The Xcode project mirrors SwiftPM target dependencies and source memberships.

World coordinates are right-handed, +Y up, with the surface centered on the origin; the
Wormhole rim is at y=0 and the throat at y=-depth. No Lorenz display-axis transform is
applied. `CameraProjection` uses the existing orbit/pan/perspective convention and is tested
against the Lorenz projection. Each scene owns its camera. Static surfaces redraw only on
input/resize; no simulation clock, decorative motion, or timeline is involved.

The renderer owns its command queue, pipelines, depth states and immutable mesh/grid buffers.
A surface vertex is three float4s (position, normal, normalized UV; 48 bytes), with UInt32
triangle indices. Default topology is 192x96 cells, duplicated seam vertices; it remains
constant while displayed parameter-grid density changes. Mathematical edits create a fresh
mesh snapshot/buffers, retained by in-flight commands; camera/style/density edits reuse them.
At most three app commands are in flight; there is no rendering-path readback or GPU wait.
A failed resource build does not commit a partial cache key.

A single opaque, two-sided surface pass uses depth32Float and a linear shader output into
bgra8Unorm_srgb. Wireframe uses antialiased UV isolines with a canvas-colored hidden-surface
fill, avoiding mesh diagonals and rear curves showing through. Shaded mode adds restrained
two-sided diffuse fill; neither mode is a transparent or PBR material. Derivative-based
coverage attenuates unresolved grid cells. A second optional draw emits screen-space quads
for coordinate planes, axes and ticks, depth-tests against the surface without depth writes,
and uses premultiplied alpha. Axis letters are projected SwiftUI annotations; spacing and
axis color meanings are also present as accessible inspector text. Depth/drawable attachments
belong to MTKView and resize with it. Resource/shape tests are not substitutes for GPU/visual QA.


## M3.1 torus geodesics

M0–M2 accepted per user on 2026-11-02. `WorkspaceCore/TorusGeodesic.swift` owns the Double
metric, (u,v,u-dot,v-dot) RK4 solver, ring trail and testable fixed-step playback. The shared
clock now owns the unchanged 1/240 s constant used by Lorenz and geodesics. No solver code
lives in SwiftUI or Metal. Initial speed is metric-normalized; velocity is not renormalized
while integrating. Non-finite or >2% speed drift stops with an error, never random recovery.

`GeodesicSession` adapts this playback to an existing `SurfaceSession(.torus)`. Initial-condition,
speed/radius/history edits deterministically restart while preserving camera/pause; fade and
representation edits do not restart. One active gallery preview computes eight real seconds,
then pauses; opening the experiment starts at t=0 with one history point. Restart has no pre-roll.
`SurfaceViewport` retains M2's camera path and static behavior when no geodesic is supplied;
with one supplied it runs a 60 Hz requested display loop, capped fixed-step catch-up, and clears
wall anchors on pause/restart and observed unavailable/minimized drawables. Achieved FPS is
not guaranteed. Diagnostics update once per second; the full mutable playback is observation-ignored.

The standard mathematical embedding is Z-up. Display maps (x,y,z) to (x,z,y) to match M2's
Y-up torus exactly. This is an isometry, including its orientation reversal; metric/equations
remain in the requested standard coordinates. Periodic coordinates wrap after full RK4 steps;
trail segments join mapped world positions and have no UV interpolation across a seam.

`SurfaceMetal/GeodesicTrails.swift` adds two thin-quad overlay draws (trail and round particle
marker) after the unchanged M2 surface pass. Surface depth is explicitly stored/loaded between
passes. Overlay tests depth without writes and uses a small raster depth bias, not displaced
simulation positions. Rear paths/particle are occluded; alpha is premultiplied into the sRGB
attachment. The marker's center is on the mapped surface; its finite pixel footprint is a
billboard, not a physical sphere. Vertex uniforms are float4x4 + float4 + uint4 + float4.
Each ring sample uploads xyz plus a reserved w (16 bytes); three persistent 8192-sample buffers
rotate under the existing three-in-flight limit on the same serial queue. No per-frame Metal
buffer creation, GPU readback or GPU wait. Mesh cache changes only for actual radii edits.
Full-ring upload is deliberately simple (~128 KiB/draw maximum), with no GPU single-particle solver.


### M3.1 continuous particle following

`ParticleCameraTracking` is a small pure policy beside `CameraProjection`: it resolves a
base camera against the latest particle position without changing yaw, pitch or distance.
Enabling follow clears old pan to center the particle; subsequent pan is an intentional
framing offset. Disabling freezes the target at the current particle location, avoiding a
jump to the pre-follow target. Restart/initial-condition changes retain follow mode. Camera
reset and Restore Defaults disable it. The inspector and native ⌘0 command use the same reset.

`SurfaceViewRenderer` integrates first, resolves one camera, then uses it for both the M2
surface and trajectory passes. It does not mutate the observable base camera per frame.
When coordinates are visible, a separate observed camera snapshot updates only the small
`GeodesicAxisLabels` child, so labels use the drawn view rather than a stale base target.
Following neither advances the solver nor changes the timestep; paused redraws stay fixed.
Depth testing remains active: following centers the particle but does not expose it through
the torus. Camera collision avoidance/automatic normal-based rotation are not implemented.


## M3.2 Ellis spatial geodesics

`WorkspaceCore/EllisWormhole.swift` is a separate concrete Double metric/embedding/RK4 solver
and bounded playback, preserving the Torus equations. l is signed/unwrapped; φ alone is periodic.
Unit energy and angular momentum are monitored without correction or renormalization. The
reference solver can continue beyond the displayed mesh; playback explicitly pauses on its
first full step outside |l|=extent, retaining that actual state and showing a boundary notice.
No bounce/reseed or silent mathematical clamp. Reference/geometry tests cover both regions.

`SurfaceMotionSession` is a narrow main-actor viewport/transport interface shared by the two
surface experiments. Torus conforms through thin adapters to its unchanged playback. New
`WormholeSession` owns the Ellis model and a `SurfaceSession` for existing camera/grid/inspector
state; `WormholeInspector` supplies only metric-relevant launch and presentation controls. The
viewport selects an explicit Ellis mesh overload, never the M2 single-branch funnel model.

The Ellis mesh shares SurfaceVertex/index layout and SurfaceRenderer. Samples are uniform in
w=asinh(l/a), so embedded height is uniform and throat detail is retained. One shared l=0 row
joins both regions. Default resolution 192×128; the cache key distinguishes M2 geometry from
Ellis parameters. Shapes rebuild only on a/extent edits. Modes/opacity/camera/motion reuse buffers.
The throat reference has its own small persistent 128-segment buffer rebuilt only when a changes.

Surface opacity uses a color-masked nearest-depth prepass followed by premultiplied coverage
without depth writes. This gives stable nearest-sheet shading/occlusion, not sorted multi-layer
transmission. Opacity zero/Trajectories skips the surface/depth entirely. Wireframe uses the same
hidden-line UV coverage as M2. M2/Torus keep their opaque one-pass path and previous material.
Alpha-only pipelines are built lazily for Ellis, so older viewports do not create/use them.

The shared trail renderer accepts visibility flags, a displayed head override and configurable
raster depth tolerance (Torus default unchanged; Ellis 0.01 world units for its mesh). It still
uses three persistent slots and one serial queue; no per-frame GPU allocations/readback/waits.
Ellis presentation interpolates signed l and shortest φ between the last two fixed states using
clock remainder, then re-embeds, so particle centers remain on the analytic surface. Running
presentation lags by at most one dt; pause/step shows the exact state. Follow uses precisely this
presentation position with the established fixed-orientation rig. No damping/camera-normal flips.


### M3.2 optional rounded return edge

`RoundedWormhole.swift` supplies a separate implicit surface and CPU Double RK4 solver.
The original two funnel sheets are preserved until the return strip on the 72-unit-wide
field; there they join through a near-semicircular section. The +X edge is closed; the other three displayed edges remain
open. `F=(y+d)^2−b² acosh(r/a)^2 h(x)`, where q=(x−(edge−width))/width and
width=min(0.65 edge,b acosh(edge/a)). h=1 before the strip; h=1−q² after q=0.2.
For 0<q<0.2 use h=1−q² S(q/0.2), with C4 smoothstep
S(t)=126t⁵−420t⁶+540t⁷−315t⁸+70t⁹. This blends into the ellipse without
an abrupt curvature change. Analytic derivatives are shared by normals and acceleration. The implicit gradient is nonzero at the join.
Acceleration is `−∇F (vᵀ Hess(F) v)/|∇F|²`, the normal acceleration of a geodesic.
RK4 state/velocity are never projected or renormalized. Constraint, tangent and energy
errors stop playback on explicit limits; angular momentum is not conserved by this
non-axisymmetric geometry and is not presented as an invariant.

The optional playback is separate from the unchanged open-funnel/Torus solvers. Fixed dt,
64-step catch-up, bounded history, transport and follow policies are reused. Interpolated
display points receive two Newton corrections to F=0 without changing solver state.
The renderer consumes the existing vertex format, a cached mesh with a welded +X edge,
and the existing trail buffers/pipelines. No new rendering pass or GPU readback is added.
Both sheets are required while this option is active. See the rounded-edge evidence report.


### M3.2 escaped-track lifecycle (2026-11-03)

Open-funnel and rounded tracks retire independently when max(|x|,|z|) exceeds
fieldHalfExtent+4. This is a display/simulation lifecycle cutoff, not a physical
reflection or capture rule. Retired tracks retain their final numerical state and
bounded history for diagnostics, stop taking steps, and are omitted from the render
batch (particle and trail together). Empty batches skip the overlay pass. Restart
restores tracks; follow now holds a retired selected ball’s last camera target until relaunch. Pure solvers retain their
unbounded mathematical domain. The larger field uses extent=52 to cover its corners;
accepted static M2 geometry and Torus remain unchanged.


### M3.2 continuous launches and centered markers (2026-11-04)

`WormholeLaunchSettings` and `WormholeLaunchStream` live beside the comparison model.
Continuous comparisons use one fixed-step clock for physics and launch scheduling, with
unchanged dt=1/240 and 64-step catch-up. Every two simulation units, one waiting slot
launches; retired slots wait at least two simulation units before reuse. When Start together is off, initial waiting
slots are hidden. The default starts the exact full row together before recycling. Active trajectories are never replaced; a full active pool suspends
emission while existing motion continues. Count and history stay bounded (maximum 17).
Single-burst mode retains its previous path; restart resets the scheduler and generation
counts. Presentation interpolation uses the shared clock remainder; pause/step is exact.

A UInt64 seed, slot index and generation determine initial x/z jitter (at most 0.6 world
units times variation) and heading jitter (at most 0.04 radians times variation). Launch
speed stays normalized; no randomness enters integration. Invalid jitter falls back to
the user start. Variation zero reproduces the exact launch conditions. Determinism has
the existing same hardware/compiler/precision limits. No persistence is introduced.

The app defaults to continuous mode, variation 0.5, seed 42, speed 2×. Follow keeps intent for a
hidden/recycled selected slot, holding its last camera target and smoothly reacquiring its replacement. The ball and trail
share a center; sphere radius affects shading/depth only, with no normal-direction lift.
Torus's existing point-marker path is unchanged. Rounded meshes use 256 angular columns;
the connector grid uses an angular coordinate around the bend to avoid squeezed cells.
Existing Metal formats, three upload slots, queue, cache and passes are reused.


### M3.2 grid coordinate and row-start refinement (2026-11-04)

Rounded mesh vertices now store a stable return angle in the unused third UV component:
atan2(q,sqrt(h)), clamping q to [0,1]. The shader interpolates this coordinate instead of
applying asin to interpolated Float x near the vertical tangent. Vertex stride/layout,
buffers and numerical geometry are unchanged. This addresses tangent amplification of
mesh/Float interpolation error; actual GPU screenshot review remains pending.

Continuous launch settings add Start together (default true). Initial tracks use the exact
row, and the stream marks them active immediately with generation 1. Subsequent escaped-slot
recycling retains its staggered schedule and seeded jitter. Open comparison restart rebuilds
from the stored original beam so recycled, varied launches cannot become the next initial row.
Turning Start together off preserves the previous staggered initial emission mode.


### M3.2 follow intent across relaunches (2026-11-04)

`RelaunchCameraTracking` is a pure camera policy beside the unchanged Torus
`ParticleCameraTracking`. The Wormhole passes an optional presentation position;
absence holds the last target without disabling follow. A returning target starts
0.6 seconds of cubic easing from the held target toward its current moving position.
This uses bounded render elapsed time, independent of the physics/playback multiplier;
pause contributes zero elapsed. Reduce Motion skips the easing. Selecting an active
ball snaps immediately; selecting a waiting slot holds and waits. Disabling freezes
the current camera target; Camera reset/defaults disable follow. Orbit, distance and
user pan remain camera inputs. No solver, randomness, buffer or Metal pass changes.

Mutable per-frame camera tracking is observation-ignored. Only follow enabled/status
changes are observed, exposing waiting/returning/following text in the inspector without
publishing every interpolated target as workspace state.
