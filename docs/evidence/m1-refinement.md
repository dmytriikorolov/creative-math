# M1 visual refinement — 2026-10-31

Status: implementation and host checks complete; **visual/GPU/performance acceptance pending**.
Stop here for visual review. No M2, custom formula editor or additional system was added.

## What changed

- Classic and Filament retain screen-space line quads and their restrained palettes.
- Sculpture now uses a separate world-space strip pipeline. Endpoint offsets come from a
  transported side vector, rather than the camera-facing perpendicular used for lines. Adjacent
  segments share endpoints; there are no length-dependent miters. Width is 0.32 world units by
  default, adjustable from 0.04 to 1.2 in the contextual Ribbon Width control.
- Simple two-sided directional diffuse + Blinn-Phong highlights give the bronze strips depth.
  These are thin translucent surfaces, not volumes or a physically based metallic material.
  There is no shadow/post-processing pass, depth attachment, or transparency depth sorting.
- Parallel transport uses the old/new Lorenz tangents in display coordinates, projection back
  onto the tangent plane, sign continuity and an antiparallel fallback. Zero/non-finite tangents
  get deterministic unit fallbacks; zero-length segments are omitted. A whole-segment near-plane
  guard prevents a single rejected endpoint from producing a spurious large triangle.
- Side vectors use octahedral encoding: two 12-bit components stored as a finite 24-bit integer
  in the existing history/state float4.w. Every such integer is exactly representable in Float32;
  there is no NaN bit reinterpretation. History remains 16 bytes/point; state remains 32 bytes/path.
  No normal buffer, extra history allocation, CPU-generated geometry, or per-frame readback.
- Frame updates run on the GPU only for spatial ribbons, fused with the existing integration
  dispatch. XYZ RK4 is unchanged. Rendering still uses six vertices (two triangles) per visible
  segment; samples guaranteed past their fade window are omitted from the draw range.
- Changing representation restarts seeded pre-roll so the history never contains stale frames.
  Width/fade edits change draw uniforms without restarting the paths or camera. Selecting a
  preset restores its full typed appearance, parameters, counts and camera.
- All presets now use the same default camera pose for comparable views. Orbit/pan/zoom are
  preserved; this shared pose makes the geometry difference directly inspectable.

## Fade contract

For a logical sample j (oldest=0) among count valid samples:

    age = (count - 1 - j) * dt, dt = 1/240 nominal simulation time
    A(age) = 1                                  when age <= delay
             0                                  when age > delay and duration = 0
             1 - smoothstep(0,1,(age-delay)/duration) otherwise

Delay and duration are independent, finite values in 0…30 simulation-time units. The GPU uses
Float32 rounding of dt/controls. Native speed changes how quickly these units elapse, not the
curve. Rendering/zooming during pause does not change the head/sample indices and therefore
cannot age a trail. A single fixed step advances retained samples' age by exactly one dt.

Finite history duration H = (trailLength - 1)*dt imposes a separate limit. Multiply A by:

    B(age) = smoothstep(0, min(0.25,H/4), H-age)

This eviction taper starts as samples approach capacity, even before the buffer fills. It avoids
an abrupt fade activation on the first full buffer. Requested values are not silently changed
or backed by a larger allocation: if delay+duration exceeds H, the buffer limit wins. The
inspector shows H. Final coverage also includes preset opacity, edge feathering and, for lines,
the existing depth attenuation. The spatial material's lighting is independent of sample age.

| Preset | Representation | Paths × history | Delay | Duration | Width |
|---|---|---:|---:|---:|---|
| Classic | Scientific lines | 12 × 2048 | 2 | 5 | 0.85 physical px |
| Filament | Fine layered lines | 24 × 3072 | 1 | 9 | 0.55 physical px |
| Sculpture | Lit spatial ribbons | 6 × 4096 | 3 | 9 | 0.32 world units |

These are configured art-direction settings, not visually approved results.

## Inspector

The existing bounded ScrollView now receives the remaining panel height explicitly. Its inner
content retains natural height and has extra bottom padding; text can wrap/scroll instead of
compressing against the rounded panel edge. Secondary explanatory text uses the 13 pt body
role. Fade Delay/Duration are always present; Ribbon Width appears only for Sculpture.
Sigma/rho/beta and both reset actions have specific native tooltips. Native controls remain.

The dedicated PanelMouseRegion and the workspace move/resize/snap/clamp/save helpers were
compared with the pre-refinement versions and are unchanged. New controls still live in the
existing body, outside the header/resize hit regions. Actual clipping/focus/scroll behavior needs
desktop review; source changes alone are not evidence that every visual defect is gone.

## Checks actually run

- `TMPDIR=/private/tmp/ ./scripts/test.sh`: **30 functions executed/passed, 3 GPU functions
  skipped** (33 discovered). [Log](m1-refinement-tests.log).
  New CPU coverage includes fade endpoints, monotonicity, delay/duration=0, invalid inputs,
  history truncation, paused age, one-step aging, pole/reversal/zero/invalid tangent handling,
  finite/exact Float32 frame packing, a direction grid and 3000 Lorenz steps of packed transport.
  Existing math, camera projection and panel geometry/preferences regressions also pass.
- New GPU test is provided, **NOT RUN here**: position equality between line/ribbon integration,
  packed-side orthogonality, actual ribbon raster output, unchanged image/history during a
  paused redraw, width-dependent coverage, fade-dependent coverage, line raster output and
  unchanged history capacity. Existing GPU parity/recovery tests also skip without a device.
- `TMPDIR=/private/tmp/ ./scripts/build-app.sh release`: **PASS**, rebuilt and signed app.
  [Build log](m1-refinement-build.log). Signature verification also passes.
- Xcode project plist, all source memberships and scheme target references: **PASS** (static).
  UI-test Swift syntax parse: **PASS**; full XCTest compilation/execution **NOT RUN**.
- Full xcodebuild cannot run: only Command Line Tools is installed. [Log](m1-refinement-xcode.log).
- Launch via this session fails with Launch Services -10827. Probe reports no Metal device,
  no visible windows and screen capture access false. [Launch log](m1-refinement-launch.log).
- Both matched performance attempts exited 2 before measurement: [line](m1-refinement-line.log),
  [ribbon](m1-refinement-ribbon.log). No comparison JSON was produced. Frame timings, sustained
  FPS, memory allocation measurements and relative cost: **NOT MEASURED**.
- Runtime MSL compilation and actual GPU execution: **NOT VERIFIED**. Host Swift compilation
  does not validate the runtime shader string. **VISUAL QA NOT RUN; no screenshots captured.**

## Performance comparison on the target Mac

Run sequentially from a normal desktop Terminal with GPU access:

    ./scripts/validate-lorenz.sh --preset sculpture --representation line --seconds 60 \
      --output docs/evidence/sculpture-line.json
    ./scripts/validate-lorenz.sh --preset sculpture --representation ribbon --seconds 60 \
      --output docs/evidence/sculpture-ribbon.json

These hold camera, seed, parameters, trajectory/history counts, fade, opacity and resolution
constant while switching compute-frame work and rendering representation. They report CPU/GPU
median/p95/p99, completed rate, drops, failures, thermal/power state and Metal allocation at end.
Use the same power mode and GPU load; repeat in reverse order to check thermal/order bias.
For sustained comparison, use 600 or 1200 seconds. Offscreen results exclude SwiftUI/compositor
cost and peak process memory; inspect the Release app with Instruments too.

Ribbon work includes transported-frame ALU, more neighboring-history reads, world-space offsets
and normal-based fragment lighting. Lines use the cheaper screen-space extrusion/unlit fragment.
Vertex-count limits and history byte capacity remain bounded in both modes. No speedup, 60 FPS,
thermal-compliance or total-memory claim can be made without measurements.

## Desktop visual review before acceptance

Quit the old running app (Cmd-Q), then open the rebuilt bundle:

    open "/private/tmp/creative-math-build/Creative Math.app"

Select each preset, pause, reset camera (Cmd-0), and capture clean/inspector views at 1440×900
and 1280×800 pt. The camera is identical across all three defaults. Use actual macOS window
screenshots (Shift-Cmd-4, Space), saved under docs/evidence. Review that Sculpture reads as
turning surfaces at the same angle, not simply thick/recolored lines. Inspect bronze highlight
clipping, edge-on behavior, sharp bends, zoom limits and partial near-plane clipping.

Change fade controls while paused, step once, resume at several speeds, and reduce history below
the requested fade window. Confirm the eviction taper and no wall-time aging. Drag Ribbon Width
through both limits while orbiting. Repeatedly switch presets; check that controls reset and
Ribbon Width disappears for line presets. Recheck header/edge interaction and saved dimensions.

The UI test captures all preset looks from their common camera, checks contextual controls and
scrolls to the inspector footer to assert that it fits above the panel's bottom border. These
screenshots/tests are provided for desktop execution and have not run here. Also review keyboard
focus, VoiceOver/help, compact 900×600 layout, Retina, resize and background/foreground behavior.

Stop after reviewing this M1 refinement. M1 remains unaccepted; M2 has not begun.

## Reset and explanation follow-up

Inspector reset is now labelled Restart: it rebuilds seeded, pre-rolled history using current
settings, preserving camera and pause state. A separate Restore Preset Defaults action calls
the existing preset selection path to restore configuration, appearance, speed and camera.
Every numeric control now displays its explanation inline; preset descriptions explain the
flow, layered threads and spatial ribbons in plain language in both gallery and inspector.
Changed files: LorenzInspector.swift and WorkspaceCore/Lorenz.swift. No renderer changes.

Follow-up `TMPDIR=/private/tmp/ ./scripts/test.sh`: exit 0, 30 passed, 3 GPU tests skipped.
`TMPDIR=/private/tmp/ ./scripts/build-app.sh release`: exit 0. Logs are in
/private/tmp/creative-math-help-tests.log and /private/tmp/creative-math-help-build.log.
Desktop launch remains unavailable (-10827); VISUAL QA NOT RUN. Manually verify inline text
at 1440×900 and 1280×800, scrollability at minimum panel dimensions, and compare Restart
against Restore Preset Defaults after changing controls and moving the camera.
