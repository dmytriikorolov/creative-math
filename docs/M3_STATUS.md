# Creative Math — M3 capabilities and progress

As of 2026-11-04. This is a standalone handoff for discussing progress in ChatGPT.
Project: native macOS mathematics/art workstation, Swift 6 + SwiftUI + Metal.

## Milestone status

| Slice | Implementation | Acceptance |
|---|---|---|
| M0–M2 | App foundation, Lorenz, static Wormhole/Torus surfaces | Accepted by user on 2026-11-02 |
| M3.1 Torus Geodesics | Implemented, including live playback/appearance and follow refinements | Actual animation approval pending |
| M3.2 Wormhole Geodesics | Implemented and actively refined from user screenshots | Not accepted; current visual/device checks pending |
| M3.3 Vector Fields | Not started | No implementation or acceptance |

**M3 as a whole is not complete.** Keep the fixed M0–M8 numbering. Do not start
M3.3 or later features without the next explicit scope decision.

## Shared M3 capabilities

- Separate gallery entries for animated Torus and Wormhole studies, with previews
  generated from actual numerical trajectories. Static M2 studies remain available.
- Play/pause, single fixed step, restart, restore defaults and camera reset.
  Shared shortcuts: Space, Command-], Command-R and Command-0 respectively for
  pause, step, restart and camera reset.
- Orbit, pan, zoom and particle following. Following preserves camera orientation
  and zoom; it does not automatically avoid surface collisions or reveal occluded paths.
- Existing draggable, resizable, snapping, scrollable native inspector; precise numeric
  fields and accessible control labels. Interface review on a real desktop is pending.
- CPU Double mathematics independent of SwiftUI/Metal. Classical RK4, fixed dt=1/240,
  wall-gap cap 0.25 seconds and at most 64 catch-up steps per draw. Excess catch-up
  time is discarded; slow rendering does not enlarge the solver timestep.
- Pause freezes simulation/history aging; step advances one fixed interval. Restart
  restores initial conditions. Mathematical/launch edits restart the affected study;
  appearance edits preserve the trajectory.
- Bounded trails: 256–8192 samples, fade delay/duration controls, no unbounded history.
  At maximum capacity, retained time span is about 34.13 simulation units/seconds.
- Shared cached Metal surface renderer and depth-tested trail overlay; three persistent
  GPU upload slots. No per-frame GPU readback or blocking GPU wait in the render path.
- Deterministic replay under the same settings, seed, executable/hardware/precision
  assumptions. Bit-identical cross-hardware/compiler results are not promised.
- Inputs and non-finite/numerically unstable states are checked. Playback reports an
  error rather than silently projecting, renormalizing, bouncing or reseeding a solver.

## M3.1 — Torus Geodesics

### Mathematics

One particle follows the metric of the accepted torus surface, not an authored animation.
The model uses A(v)=R+r cos(v), metric diag(A²,r²), and metric-derived geodesic equations.
Initial direction is measured in an orthonormal tangent frame, so changing position does
not accidentally change initial speed. Periodic coordinates wrap without world-space
trail jumps. No force, random steering or runtime velocity renormalization is applied.

Tests cover metric/embedding agreement, equations, speed normalization, equatorial
circles, near-equator behavior, periodic seams, conservation drift, convergence,
extended trajectories, repeatability, pause/step/restart and bounded history.

### User controls

- Initial u/v: 0–360 degrees; launch direction: −180–180 degrees.
- Surface speed: 0.25–8 world units per simulation second.
- Major radius R: 4–9; tube radius r: 0.5–3 (R remains greater than r).
- Live playback multiplier: 0.125–4, default 2×.
- Particle diameter, trail width, history capacity, fade delay/duration.
- Shaded/wireframe surface representation and optional coordinate grid.
- Follow particle, manual camera controls, camera reset and preset defaults.
- Diagnostics: simulation time, relative speed drift and discarded catch-up time.

Defaults: R=6, r=2, u=30°, v=22.5°, direction=65°, speed=4. A single particle and
its trail are implemented; no Torus particle stream or multi-particle comparison is claimed.

## M3.2 — Wormhole Geodesics

### Geometry and motion

The current app restores the original funnel profile, extended into a 72-unit square
viewing region. Upper/lower sheets join at the throat. The lower sheet can be shown or
hidden without changing the equations. This is a spatial surface-geodesic study, not
gravity, photon motion, gravitational lensing or full spacetime simulation.

The open funnel uses its actual induced metric with signed radial coordinate and periodic
azimuth. Unit-speed tangent launches can cross the throat or deflect outward. The original
pure Ellis reference model remains in the code/tests; it is not a separate additional
current UI mode with all of the old prototype controls.

Optional **Rounded return edge (+X)** joins the two sheets at one outer side. Its
near-semicircular section blends smoothly into the funnel using a C4 transition. An
independent implicit-surface solver follows the edited shape, using analytic gradient
and Hessian. Angular momentum is not an invariant of this non-axisymmetric surface and
is not reported as one. The other three outer sides remain open. Open funnel is the default.

### Balls, row launch and continuous mode

- 1–17 simultaneous track slots; default 13. Initial row: x=−18, z=−4.8…4.8,
  common heading +X, with every tangent normalized to unit intrinsic surface speed.
- Edit row count, X position, Z offset and width, then apply with **Place starting row**.
  Individual Start X/Z and common heading can also be edited.
- **Continuous launches** defaults on. **Start together as a row** now also defaults on:
  the complete initial row appears together at its exact user-defined positions, with
  no random perturbation on that first row. Restart restores that same row.
- Turn Start together off for staggered initial launches. Turn Continuous launches off
  for a single simultaneous comparison without recycling.
- In continuous mode, escaped slots are reused one at a time, at a maximum cadence of
  one launch per two simulation units, with at least two units before reusing an escaped
  slot. The cadence uses the same fixed-step clock as motion, not render-frame counts.
- Adjustable launch variation 0–1 and UInt64 seed (UI range 0–999999; default 42).
  Randomness affects only recycled/staggered starting positions and headings, not forces
  or integration. Maximum jitter is ±0.6 world units per X/Z coordinate and ±0.04 radians
  of heading, scaled by variation. Default variation is 0.5. Invalid jitter falls back
  to the valid original start. Variation zero gives the exact configured conditions.
- A ball and its whole trail disappear four units beyond an open displayed edge; that
  track stops stepping. Retained balls are never removed just to make room. A fully
  occupied surviving pool suspends new launches while its existing particles continue.
  This is bounded continuous operation, not a guarantee of mathematically infinite runs.
- Follow a selected ball across relaunches: the toggle stays on while absent, the camera
  holds its last target and the inspector shows “Waiting for selected ball to relaunch”.
  On return, a 0.6-second camera-only transition reacquires the moving ball. Selecting
  another active ball follows immediately. Reduce Motion skips the transition; pause
  freezes its progress. Manual orbit/zoom/pan remain available. Disable or Camera reset
  ends follow. Restart clears histories and repeats the seeded launch sequence.

### Controls and presentation

- Playback multiplier: 0.125–16, default 2×. Surface speed remains normalized separately.
- Throat radius: 1–4; funnel depth: 2–12; optional rounded return edge; lower-sheet visibility.
- Surface, Wireframe and Trajectories modes; opacity, ball/trail visibility, ball size,
  bounded history, fade delay/duration and optional throat reference.
- Selected-track diagnostics: outcome/region, elapsed path parameter and energy error;
  open funnel also reports momentum error, rounded solver reports surface residual.
- Shaded ball markers are centered on their trajectory heads, rather than offset above
  the trails. Marker size is visual and does not turn these into finite-size rolling balls.

## Latest refinements and verification

The latest screenshot exposed zigzag grid lines near the rounded side. The prior shader
applied asin to interpolated Float x-coordinates near its singular derivative at the
vertical tangent. The revision calculates a stable angle in Double at mesh vertices,
stores it in an existing unused UV component, and interpolates the angle directly.
No mesh format, new GPU buffer or solver change is required for this drawing fix.
Actual visual confirmation of the fix is still pending.

The latest tests cover follow intent, waiting/hold, smooth return, immediate active
selection, Reduce Motion and camera reset. They also exercise the restored complete starting row, equal initial step
counts, exact starts without jitter, recycling and reconstruction of the original row
after varied relaunches. Both open and rounded playback are covered.

Latest executed checks (2026-11-04):

- `TMPDIR=/private/tmp/ ./scripts/test.sh`: 97 total tests; 89 passed, eight Metal
  tests skipped, zero failures; 5.748 seconds of test execution.
- `TMPDIR=/private/tmp/ ./scripts/build-app.sh release`: release packaging passed
  in 45.16 seconds; strict code-signature verification passed.
- UI test source parsing and Xcode project plist lint passed.
- Full Xcode build and UI automation NOT RUN: the environment has Command Line Tools
  only. Metal tests reported no available device.
- App launch was attempted and failed through Launch Services (-10827).
  **VISUAL QA NOT RUN** for this revision: no current app screenshots, animation
  confirmation or measured frame timing. The user screenshot is evidence of the
  previous grid defect, not proof that the revised output is accepted.

Current logs: `/private/tmp/wormhole-follow-tests.log` and
`/private/tmp/wormhole-follow-build.log`. Test duration is not an app FPS benchmark.

To review, quit the old app and open:

```sh
open '/private/tmp/creative-math-build/Creative Math.app'
```

Open Wormhole and enable Rounded return edge (+X). Continuous launches and Start
together as a row are enabled by default. Inspect the whole row before resuming if
needed, and let escaped slots recycle. Unit/GPU test status must not be confused
with actual animation acceptance.

## Remaining work and limits

1. Review the current rounded-side grid and silhouette, row launch, relaunch timing,
   ball/trail centers, depth occlusion and camera follow on the real app.
2. Capture baseline/compact/Retina screenshots (1440×900 and 1280×800) and run the
   desktop UI/Metal tests with full Xcode. Review focused/invalid/disabled controls,
   inspector scrolling/snapping/resizing and pause/step/restart behavior.
3. Measure sustained CPU/GPU timing, memory and thermal behavior on target hardware.
   No sustained M3 FPS/memory claim is established by the current CPU test results.
4. Obtain user approval of actual M3.1 and M3.2 animations. Neither is accepted yet.
5. Define/authorize M3.3 Vector Fields before implementation. No vector-field controls,
   vector solvers, field integration or visualizations are currently delivered.

Timeline/keyframes, formula editing, optimization, Black–Scholes, KKT, scene persistence,
undo/redo and export are outside this slice. The project roadmap retains those deferrals.


## Evidence and implementation map

- [M3.1 derivation and original validation](evidence/m3.1-geodesics.md).
- [M3.2 open-funnel comparison model](evidence/m3.2-comparison.md) (historical defaults).
- [Near-semicircular return, continuous launches and centered markers](evidence/m3.2-continuous-launches.md).
- [Grid-coordinate and row-start refinement](evidence/m3.2-grid-row.md).
- [Latest follow-across-relaunch policy and checks](evidence/m3.2-follow-relaunch.md).
- Core: `Sources/WorkspaceCore/{TorusGeodesic,EllisWormhole,RoundedWormhole,WormholeComparison}.swift`.
- App: `Sources/CreativeMath/{GeodesicSession,GeodesicInspector,WormholeSession,WormholeInspector}.swift`.
- Rendering: `Sources/SurfaceMetal/{SurfaceRenderer,SurfaceShaders,GeodesicTrails}.swift`.
- [Fixed milestone roadmap](roadmap.md); [short ongoing handoff](STATUS.md).
