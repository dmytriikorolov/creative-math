# Creative Math

Native macOS creative mathematics workstation. Swift 6, SwiftUI, Metal; macOS 14+.
The product name is provisional. **M0, M1 and M2 are accepted and complete** per user
confirmation on 2026-11-02. M3.1 Torus Geodesics is implemented with local animation review pending. Active work is
**M3.2 — Wormhole Geodesics**, also awaiting user review. M3.3 has not started.

## Development audit and workflow

See [confirmed project status](docs/PROJECT_STATUS.md), [reproducible development workflow](docs/DEVELOPMENT_WORKFLOW.md), and [2026-11-13 evidence/screenshots](docs/evidence/audit-2026-11-13/README.md). Run `TMPDIR=/private/tmp/ ./scripts/verify.sh check` for sequential tests, release packaging and signature verification. Full Xcode/UI and GPU device checks have separate prerequisites; see the workflow before interpreting a pass.

## App identity
The app icon uses the original Triangle Study geometry and blue. Vector sources and native
icon sizes are in `Assets`; both Xcode and `build-app.sh` package `AppIcon.icns`. To regenerate
from the vector geometry, run `swift scripts/generate-app-icon.swift Assets` from the repo root.

## Run

For quick access, double-click **Open Creative Math.command** in this project folder.
It builds the latest release incrementally and opens the app. The first build takes longer.
Once open, right-click its Dock icon → **Options → Keep in Dock** to reopen that build directly.
Use the launcher again after code changes to rebuild.

Open `CreativeMath.xcodeproj` in Xcode 16 or later, select the **CreativeMath** scheme and **My Mac**, then Run. Full Xcode is required for the Xcode build and UI tests.

With Command Line Tools only, build a local development app:

```sh
./scripts/build-app.sh
open "${TMPDIR:-/tmp}/creative-math-build/Creative Math.app"
```

Use `./scripts/build-app.sh release` for profiling an optimized app build.

Run math, fixed-clock, camera and inspector tests (GPU tests run when a Metal device is accessible):

```sh
./scripts/test.sh
```

Run the complete Xcode build/test gate in a logged-in macOS desktop session:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project CreativeMath.xcodeproj -scheme CreativeMath \
  -destination 'platform=macOS' -derivedDataPath /tmp/CreativeMathDerivedData \
  CODE_SIGNING_ALLOWED=NO build test
```

## Lorenz workspace

- Select **Classic**, **Filament** or **Sculpture** in the gallery, then Open. Previews use the
  actual GPU simulation, deterministically pre-rolled and paused.
- Drag the canvas to orbit; Shift/Option-drag, right-drag or middle-drag to pan. Scroll or
  pinch to zoom. With canvas focus, arrow keys orbit and +/− zoom. **⌘0** resets the camera.
- **Space** pauses/resumes; **Step / ⌘]** advances exactly one RK4 step while paused. **⌘R** resets
  the simulation with the current parameters and seed. Camera and simulation reset independently.
- Native **Simulation** and **Camera** menus keep these commands available when the inspector is hidden.
- Edit σ, ρ, β and speed with sliders or precise numeric fields. Enter commits; Escape reverts.
  Invalid/non-finite/out-of-range values stay uncommitted and show an error.
- Model edits continue from the current state and clear previous trails. Trajectory-count and
  trail-point sliders apply on release and restart the seeded paths. Presets restore their
  configuration, appearance and camera; reset/preset selection preserve pause state.
- The inspector body scrolls; resize the panel to expose more controls. Diagnostics show actual
  completed-command rate and CPU/GPU timing when available, not a promised display frame rate.
- **Fade Delay** and **Fade Duration** use simulation-time units and freeze with the simulation.
  A smoothstep curve fades old segments; the finite history ends with a short eviction taper.
- **Sculpture** uses spatial ribbons with simple two-sided bronze lighting. Its contextual
  **Ribbon Width** control uses world units (0.04–1.2). Classic and Filament remain thin lines.
  Appearance edits redraw existing history; preset selection restores preset appearance values.

Math, reset/pre-roll semantics, precision limits and acceptance evidence: [M1 record](docs/evidence/m1.md).

Historical ribbon/fade/inspector implementation and validation record:
[M1 refinement record](docs/evidence/m1-refinement.md). All three presets now reset to the same
camera pose for direct comparisons; orbit/pan/zoom remain available.

## Geometry & Surfaces

The **Surfaces / Wormhole and Torus** gallery section provides explicit Open buttons for both.
The Wormhole here is the accepted static M2 surface. The separate **Wormhole comparison**
study below adds spatial particle motion on a two-region metric. Both use the same
Metal mesh renderer and the existing floating inspector/camera gestures. Surfaces are static
and draw on demand; no timeline or simulation runs in the background.

- **Wireframe** shows fine parameter curves with hidden-surface removal (no triangle diagonals).
  **Shaded + grid** adds a restrained opaque fill. Surface grid density is independent of the mesh.
- Wormhole: adjust rim radius, throat radius and depth. Depth 0 is a flat annulus; increasing
  depth bends it into an open funnel. This is a geometric surface, not a spacetime simulation.
- Torus: adjust major and tube radii. The validated range keeps the ring free of self-intersection.
- Enable **Coordinate grid** for three coordinate planes, colored axes and ticks. **Grid divisions**
  sets tick spacing over ±15 world units. Axis letters and the inspector explain the coordinates.
- Drag to orbit; Shift/Option/right-drag to pan; scroll or pinch to zoom. Arrow keys and +/−
  work with viewport focus. **Reset Camera / ⌘0** restores the preset view; **Restore Preset
  Defaults** also resets the surface, representation and grids. Lorenz transport stays separate.

Formula/mesh tests, implementation details and historical desktop checks:
[M2 validation record](docs/evidence/m2-surfaces.md). No reference video was available in this
session; the Wormhole visual review has since been accepted by the user.

## Torus Geodesics — M3.1

Open **Torus Geodesics** in the gallery. Its preview is eight seconds of real CPU integration,
paused; the experiment starts at t=0 and grows a bounded amber trail with one bright particle.
The accepted M2 torus/camera/inspector are reused. No random steering is involved.

- Initial u/v are degrees around the ring/tube; v=0° is the outer equator, v=180° the inner.
- Launch angle 0° points along +u, +90° along +v, measured in the metric's orthonormal tangent
  frame. Speed is surface distance per simulation second, independent of launch position.
- **Playback (×)** changes live from 0.125× to 4× (default 2×), keeping the same fixed dt.
  Physical launch **Speed** remains distance per simulation second.
- **Particle size (pt)** and **Trail width (pt)** improve visibility without resetting the path.
  **Follow particle** continuously tracks the current sample while preserving your orbit
  angle and zoom. Pan adjusts the framing offset. Turning it off freezes the current view;
  **Camera / ⌘0** stops following and restores the full torus. Pause and single-step update
  the camera with the same solver state. Geodesic zoom reaches distance 1.
- Initial position/direction, speed, radii and trail-length edits restart deterministically,
  preserving camera/pause. Fade and representation edits redraw without restarting.
- Space pauses/resumes; **⌘]** advances exactly 1/240 s when paused; **⌘R** restarts at current
  initial conditions; **⌘0** resets the camera. Restore Preset Defaults also restores appearance
  and camera, preserving pause. Existing floating inspector drag/resize/snap/persistence remain.
- Trail age uses simulation time. Maximum 8192 points retain about 34 seconds; fading and a
  capacity taper limit older history. Diagnostics report measured relative speed drift and
  dropped simulation time. RK4 does not conserve speed/energy exactly.

Derivation, numerical measurements, tests and exact desktop verification:
[M3.1 evidence](docs/evidence/m3.1-geodesics.md).

## Wormhole comparison — M3.2

Open **Wormhole** in the gallery. The original funnel now has a wider, nearly flat square
grid and a pool of 13 balls. In simultaneous comparison mode they share a planar heading
and unit surface speed; changing their starts changes which cross or deflect outward.

Use **Place starting row**, or edit the selected ball's Start X/Z. Position and shape edits
restart the comparison together. **Show other region** reveals the connected lower surface.
Pause/Step/Restart, Follow selected ball, orbit/pan/zoom and Camera/⌘0 remain available.
Playback starts at 2× and is adjustable from 0.125× to 16×; the fixed 1/240 solver step
and 64-step catch-up budget remain unchanged. Slow rendering can limit achieved playback speed.
Shape controls change throat radius and funnel depth and restart the comparison. Both regions
are shown initially. **Continuous launches** and **Start together as a row** are on by
default: the first exact row launches together; escaped slots relaunch one at a time
every two simulation units (one second at 2×). Turn Start together off to stagger the
first launch as well. Only escaped slots are recycled; particles
remaining on the surface are kept. The bounded pool holds up to the selected ball count
(maximum 17). If every slot remains on the surface, launches wait while those balls continue.
**Launch variation** controls small position/heading changes; **Launch seed** makes them
repeatable on Restart. Set variation to zero for exact starting conditions, or turn continuous
launches off to compare the simultaneous starting row. Launch edits restart motion.
Starting-row and individual-start controls are grouped in disclosure
sections; row edits require **Place starting row**. Fine appearance controls are also collapsed.
Enable **Shape → Rounded return edge (+X)** to connect the outgoing edge to the lower
sheet. The field is 72 units across, with a near-semicircular return and a smooth approach.
Balls follow the curved join without bouncing or restarting. The other three
edges remain open. This optional surface uses its own implicit-surface geodesic solver;
toggling it restarts the comparison and shows both sheets. The open funnel stays the default.

Balls are shaded sphere markers centered on their geodesic points, sharing the exact
position of the trail head. Their visual size does not affect the mathematics.
Surface/Wireframe/Trajectories affect presentation only. Balls and their trails disappear
four world units beyond an open grid edge. Each escaped track stops independently; the
remaining balls continue. Continuous mode relaunches escaped slots after a delay. Restart
repeats the launch sequence. Following stays enabled when its selected ball disappears: the camera holds, shows
“Waiting for selected ball to relaunch”, then returns smoothly on relaunch. Selecting
another active ball follows it immediately. Reduce Motion skips the animated return;
history remains bounded. The original funnel's induced metric determines motion;
these are spatial geodesics, not gravitational attraction or lensing.

[Full M3 capabilities and current status](docs/M3_STATUS.md).
Neither M3.1 nor M3.2 is marked accepted.

## Shared workspace controls

- Gallery: **Triangle Study** renders a real Metal primitive; **Blank Scene** clears the viewport.
- Workspace: **⌘G** returns to the gallery; **⌘I** shows/hides the inspector.
- Drag anywhere in the inspector header except its close button. Magnetic attraction begins
  within 12 pt of the workspace's 16 pt inset boundaries and settles into a small contact zone.
- Resize from any edge or corner. Default size is 304×224 pt; limits are 280–520 pt wide and
  224–640 pt tall, further constrained to fit the workspace.
- Double-click the header to restore the default size while retaining its position where possible.
- Focus the header and use arrow keys to move it. **Restore Placement** returns it to the upper
  right without resetting its size. VoiceOver actions also support resizing and size reset.
- Position and dimensions persist in app preferences and clamp to workspace bounds on resize.
- **⌘N** opens Blank Scene from the gallery. Enable macOS Keyboard Navigation for full Tab navigation.

Triangle/Blank and surfaces draw on demand. Lorenz requests 60 Hz rendering with independent fixed-step
simulation; achieved frame rate must be measured on the target machine.

## GPU validation and sustained workload

Run these from a normal macOS Terminal with GPU access. Full Xcode is not required for this
Swift Package tool. An unavailable Metal device exits with status 2, without reporting success.

```sh
./scripts/validate-lorenz.sh
./scripts/validate-lorenz.sh --preset classic --seconds 1200 \
  --width 2880 --height 1800 --output docs/evidence/m1-classic-performance.json
```

The first command checks one-second GPU/CPU parity. The second measures actual offscreen compute
and trail rendering for 20 minutes (use `--seconds 600` for the user's minimum 10-minute test).
Reports include CPU/GPU/frame-interval median/p95/p99, completed rate, submission drops, faults,
thermal/power state and Metal allocation at end. This excludes window composition and SwiftUI;
use Instruments for actual interactive app timings and peak process memory.

For a matched line-versus-ribbon comparison, use the same Sculpture dataset and camera:

```sh
./scripts/validate-lorenz.sh --preset sculpture --representation line --seconds 60 \
  --output docs/evidence/sculpture-line.json
./scripts/validate-lorenz.sh --preset sculpture --representation ribbon --seconds 60 \
  --output docs/evidence/sculpture-ribbon.json
```

Parity is only the first phase. With `--seconds 60`, the tool then warms up the renderer,
runs for 60 seconds, drains GPU work, and writes JSON at the end. It prints the selected mode,
absolute output destination, workload start, progress every 10 seconds, and final write
confirmation. **No separate benchmark tool is required.** `--help` describes supported flags;
unknown/duplicate/missing options now fail instead of silently using parity-only defaults.
`--output` requires a positive `--seconds` and an existing writable parent directory; errors
exit 2. A parity-only invocation creates no JSON. Output paths are relative to the repository
root because the wrapper changes directory there. Existing reports are atomically replaced.

Run these sequentially, with the same resolution/power mode and other GPU work stopped.
They include each representation's compute and fragment cost; no relative speed result has
been measured in this restricted session. Use longer runs for sustained thermal comparison.

## Structure and evidence

- `Sources/CreativeMath`: app, gallery/workspace, design tokens and Metal renderer.
- `Sources/WorkspaceCore`: Lorenz CPU reference/model, typed presets, camera, clock, panel geometry.
- `Sources/LorenzMetal`: shared GPU compute, private history buffers and ribbon renderer.
- `Sources/SurfaceMetal`: indexed parametric surface, parameter curves and coordinate-grid rendering.
- `Sources/LorenzValidation`: actual GPU parity and sustained offscreen workload tool.
- `Tests/WorkspaceCoreTests`: dragging, resizing, magnetic snapping, clamping and preferences tests.
- `UITests`: gallery, scene, inspector, drag/restore, keyboard and relaunch persistence checks,
  plus Lorenz presets/controls/camera and screenshot attachments; Xcode required.
- `docs`: product vision, architecture, design system, roadmap and [M0 verification record](docs/evidence/m0.md).

Historical M1/M2 evidence is retained; the user has now accepted both milestones. M3.1
requires actual animation review before acceptance. Save/load, timeline, export and
formula editing are outside the current milestone.

The historical [gallery refinement review](docs/evidence/m0-refinement.md) records the responsive
layout, native control changes and agent-session validation limits before user acceptance.

The historical [inspector interaction record](docs/evidence/m0-inspector.md) documents resizing,
persistence, tests and the desktop checks that were pending before user acceptance.
