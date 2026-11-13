# M2 — Geometry & Surfaces, 2026-11-01

Status: implementation and host checks complete; **GPU execution, visual QA and user review
pending. M2 is not accepted.** The user authorized Geometry & Surfaces as the new M2 scope;
the previous persistence/export milestone is deferred. Lorenz's solver, compute, trails,
presets and inspector mechanics remain intact.

## Brief benchmark investigation

The repository's `LorenzValidation` executable already contains both parity and an offscreen
benchmark. `scripts/validate-lorenz.sh` forwards its arguments to that executable. There is
no separate benchmark tool to install. In the inspected implementation, positive `--seconds`
enters the workload after parity, allocates a render target, pre-rolls, runs for the requested
wall duration, drains GPU work and finally writes JSON. A parity PASS is not benchmark completion.
The two commands in the user's request are valid for this implementation.

Confirmed misleading behavior: unknown flags were silently ignored, missing values fell back
to defaults, and `--output` with omitted/zero duration returned successfully without writing
anything. There were no phase/progress messages after the parity line. This is now corrected:

- A tested typed parser rejects unknown/duplicate/missing/invalid options before Metal work.
- `--help` documents parity-only versus benchmark mode. `--output` requires a positive
  duration and an existing writable parent directory, checked before GPU initialization.
- Unbuffered stderr messages report the selected mode, render preparation, timed workload
  start/destination, progress every ten seconds and successful JSON write. JSON is written
  atomically, replacing an existing requested report. Write errors produce exit 2.
- GPU parity now explicitly rejects non-finite states; the final drain command is checked.

The original GPU-side no-JSON observation could not be reproduced here: Metal is unavailable,
so both workload attempts stop before parity. No claim is made that an unknown GPU stall has
been fixed. The new phase messages make the stopping point visible without requiring a manual
script investigation. No benchmark numbers or JSON reports were invented.

Correct procedure remains the commands already supplied (sequentially, from a desktop Terminal):

```sh
./scripts/validate-lorenz.sh --preset sculpture --representation line --seconds 60 \
  --output docs/evidence/sculpture-line.json
./scripts/validate-lorenz.sh --preset sculpture --representation ribbon --seconds 60 \
  --output docs/evidence/sculpture-ribbon.json
```

Allow warm-up + 60 seconds + GPU completion. Expect `JSON written: <absolute path>` on success,
not just parity PASS. Relative output paths resolve from the repository root (the wrapper cds
there). No duration means parity only, with no report. The measurement excludes window/SwiftUI
composition; Instruments is the separate procedure for interactive app CPU/GPU/process-memory
profiling, not a prerequisite for moving forward with this milestone.

## Implemented surface slice

- `WorkspaceCore/ParametricSurface.swift`: validated Wormhole and Torus models, Double samples
  and analytic normals; bounded indexed meshes; coordinate plane/axis/tick geometry.
- `WorkspaceCore/CameraProjection.swift`: projection used by surface rendering and axis labels,
  tested against the existing Lorenz camera convention without altering Lorenz's implementation.
- `SurfaceMetal/SurfaceRenderer.swift` and `SurfaceShaders.swift`: shared indexed, depth-tested
  two-sided surface renderer; antialiased parameter isolines; wireframe or shaded + grid mode;
  optional depth-tested coordinate scaffold. Muted neutral/cool curves, no glow or new effects.
- `CreativeMath/SurfaceSession.swift`, `SurfaceViewport.swift`, `SurfaceInspector.swift`: separate
  surface state, actual Metal gallery preview and workspace, native controls, orbit/pan/zoom,
  Camera reset/⌘0, defaults restoration, optional coordinate grid and density controls.
- `WorkspaceView.swift`, `CreativeMathApp.swift`, `PanelPlacement.swift`: surface entry/state,
  inspector routing and scene-aware camera command. Header drag, resizing, snap, placement and
  panel preferences are untouched. `LorenzInspector.swift` only exposes its existing numeric
  control for reuse; Lorenz control behavior is unchanged.
- `Package.swift` and Xcode project: SurfaceMetal target, dependencies, framework embedding and
  all new source/test memberships. No universal scene/document/plugin framework.
- New CPU/GPU tests and UI test coverage; README, architecture, product/design/roadmap and
  AGENTS milestone gate updated to reflect the explicitly changed M2 scope.

No save/load, undo system, export, timeline, Black–Scholes, KKT, custom formula editing or
optimization was started. There is no automatic animation: depth is a direct mathematical edit.

## Mathematical contract

Right-handed world coordinates, +Y up; dimensionless world units. u/v are sampled on [0,1]
with angular coordinates obtained by multiplying by 2π. The renderer consumes Float32 meshes
sampled from the Double model; it does not duplicate the surface formulas in a GPU solver.

**Wormhole** is one open branch of a scaled catenoid-like surface of revolution:

```
L = acosh(R/a),  r(v) = a cosh(v L)
P(u,v) = (r(v) cos(2πu), d(v-1), r(v) sin(2πu))
```

R is rim radius (6…14), a is throat radius (0.5…4), d is depth (0…12). Thus R>a always.
The rim stays at y=0 and the open throat at y=-d. d=0 is a flat annulus. Changing depth
vertically stretches the profile; it is a true catenoid only for d=aL, not for every setting.
Normals are proportional to (-d cos(2πu), aL sinh(vL), -d sin(2πu)); the flat throat's singular
parameter derivative gets the geometric +Y normal. This is not a spacetime/GR simulation.
No reference video was attached or found in this repository, so fidelity to that reference
cannot be assessed; the design follows the textual brief and awaits the user's visual review.

**Torus** uses R in 4…9 and tube radius r in 0.5…3, guaranteeing R>r:

```
P(u,v) = ((R+r cos(2πv)) cos(2πu), r sin(2πv), (R+r cos(2πv)) sin(2πu))
```

Both angular seams duplicate endpoints with separate UVs, so parameter-grid interpolation does
not cross from 1 to 0 within a triangle. Normals are analytic and unit length. Mesh winding agrees
with those normals. There is no timestep, seed, convergence stopping criterion or ODE here.

The fixed mesh is 192×96 cells (18,721 vertices, 36,864 triangles). Surface grid density 12…96
controls angular curves, with floor(density/2) crosswise curves; it does not change mathematical
parameters or mesh resolution. Wireframe uses UV isolines rather than triangulation diagonals.
Canvas-colored opaque fill hides rear curves; shaded mode adds a muted diffuse fill. Extremely
small projected cells attenuate to suppress moiré rather than promising unlimited detail.

Coordinates are opt-in: three planes over ±15, three colored axes, tick spacing 15/divisions
(divisions 4…24), projected axis letters and accessible inspector text describing spacing/colors.
The scaffold is depth-tested against the surface and does not write depth. Near-plane/degenerate
screen-space segments are rejected whole. It is not an infinite grid or numeric label system.

## Resources and performance limits

The renderer caches meshes across camera/style/density edits and rebuilds only after model
edits. Mesh buffers are immutable and retained by submitted commands; replacement cannot
rewrite a buffer being read by the GPU. Grid buffers change only when needed. Pipelines/depth
states persist; MTKView owns/resizes color/depth attachments. Up to three commands are in flight,
with completion-triggered redraw retry for a saturated on-demand viewport. No per-frame GPU
wait or readback is present in the app rendering path.

Calculated geometry capacity per surface viewport: 898,608 vertex bytes + 442,368 index bytes
= 1,340,976 bytes, excluding attachments/driver/UI and temporary rebuild arrays. Maximum
coordinate buffer: 435 segments × 2 vertices × 32 bytes = 27,840 bytes. One indexed surface draw,
plus one optional grid draw. These are source-derived budgets, **not process-memory measurements**.
CPU mesh-edit latency, GPU timing, sustained performance and thermal behavior are **NOT MEASURED**.
No performance speedup, target-device FPS or memory-compliance claim is made.

## Verification evidence

Environment remains arm64 with Command Line Tools, no accessible Metal device, no full Xcode.

- `TMPDIR=/private/tmp/ ./scripts/test.sh`: **exit 0**, 48 test functions discovered;
  **42 executed/passed, 6 GPU functions skipped**. [Log](m2-surfaces-tests.log).
  New CPU checks cover implicit torus equation, both seams, unit/orthogonal normals, Wormhole
  throat/rim/flat limits, finite parameter corners, mesh winding/index bounds/layout, grid
  counts/bounds, projection equivalence, and strict benchmark argument parsing. Existing Lorenz
  integration, fading, frame transport and inspector geometry tests still pass.
- Device-gated surface test compiles but **NOT RUN**: actual raster output for both presets,
  wireframe/shaded/grid/density differences, stable redraw and mesh-resource reuse. All five
  existing Lorenz GPU test functions also skip. Runtime MSL compilation **NOT VERIFIED**.
- `TMPDIR=/private/tmp/ ./scripts/build-app.sh release`: **exit 0**, built/linked/signed the final
  Release app (46.27 seconds). [Build log](m2-surfaces-build.log). Subsequent
  `codesign --verify --strict` of the app exits 0.
- `plutil -lint CreativeMath.xcodeproj/project.pbxproj`: exit 0. Static source-membership and
  target-dependency reference audit passes for all Swift source/test files. This is not an Xcode build.
- `swiftc -frontend -parse UITests/WorkspaceUITests.swift`: exit 0. UI tests include surface
  selection, flat/default Wormhole, grid toggle, Torus controls, camera, inspector and return to
  Lorenz, with screenshot attachments. **UI test type checking/execution NOT RUN** without Xcode.
- `./scripts/validate-lorenz.sh --help`: exit 0; [help log](m2-benchmark-help.log).
- `./scripts/validate-lorenz.sh --output /private/tmp/m2-should-not-exist.json`: exit 2 with a
  positive-duration requirement, before Metal access; [invalid option log](m2-benchmark-invalid.log).
- Xcode test attempt fails because CLT is selected and full Xcode is unavailable;
  [log](m2-surfaces-xcode.log). **Xcode build/tests NOT RUN**.
- Both exact requested benchmark commands were attempted after the final build: exit 2,
  correct timed mode printed, then Metal unavailable before parity/workload. No report was
  created. [Line log](m2-benchmark-line.log), [ribbon log](m2-benchmark-ribbon.log).
- `open '/private/tmp/creative-math-build/Creative Math.app'`: failed with Launch Services
  -10827, despite a verified executable/bundle. [Launch log](m2-surfaces-launch.log).
  **VISUAL QA NOT RUN; no screenshots captured.**

No `.git` metadata is present in this workspace, so no commit/diff-based claim is made.

## Local visual/device review still required

The following is a short acceptance procedure, not another benchmark-script investigation:

```sh
./scripts/test.sh                         # GPU tests must execute, not skip
TMPDIR=/private/tmp/ ./scripts/build-app.sh release
open '/private/tmp/creative-math-build/Creative Math.app'
```

With Xcode installed, run the CreativeMath scheme's tests on My Mac. Use Metal API/Shader
Validation for correctness. Capture actual app screenshots at 1440×900 and 1280×800 pt, plus
a 900×600 compact check; no screenshot/visual-review result is claimed by this session.

1. Open Wormhole and Torus from the gallery; inspect fine curves, seams, depth/occlusion,
   aliasing, restrained exposure and composition. Compare Wormhole to the reference video.
2. Wormhole depth 0 → 12, throat 0.5 → 4, rim 6 → 14; Torus both radius extremes. Verify a
   smooth open throat, no NaNs/spikes and a non-self-intersecting ring. Try both representations
   and surface density extremes, including edge-on views and Retina/window resizing.
3. Enable coordinates, vary divisions, check axes/ticks/letters and intersections with each
   surface. Confirm tick spacing in the inspector corresponds to the finite scaffold.
4. Orbit, Shift/right-drag pan, scroll/pinch/+/- zoom and ⌘0; hide/show inspector. Restore
   Defaults resets model/style/grid/camera. Switch presets repeatedly; verify contextual fields.
5. Inspect invalid/non-finite numeric entry, Enter commit/Escape revert, slider responsiveness,
   scroll to the last help text at minimum panel size, keyboard focus/VoiceOver, header dragging,
   edge/corner resizing/snap and saved placement. No UI redesign was intended.
6. Return to Lorenz: Classic/Filament/Sculpture, pause/step/Restart, camera, fade and presets
   must behave as before. UI tests now scroll adaptively to Triangle below the added gallery study.

If any rendering gate fails, capture its preset/settings and the frame/error. The next smallest
slice is device/visual correction of this implementation, not persistence/export or another scene.
