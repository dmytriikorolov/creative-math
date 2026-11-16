# Creative Math roadmap and acceptance gates

M0, M1 and M2 are **accepted and complete**, confirmed by the user on 2026-11-02.
The fixed Roadmap v1.0 uses M0–M8 numbering; do not renumber milestones. The local file
previously contained an older M0–M5 outline and no v1.0 source. This update records the
explicitly supplied M3 scope only; it does not assign new scopes to M4–M8. Legacy M4/M5
text below is retained pending the full v1.0 document, rather than inventing later definitions.

## M0 — Application foundation — ACCEPTED
Deliver: compiling native SwiftUI app, Metal viewport (clear + real primitive), gallery and blank-scene entry, design tokens, draggable inspector with edge snap, keyboard focus. Evidence: xcodebuild log, screenshots at 1440×900 and 1280×800, basic UI tests, no inert controls. Do not implement a general engine.

## M1 — One beautiful, correct attractor — ACCEPTED
Deliver: Lorenz numerical model, pause/play/reset/step, orbit camera, live parameter editing, real GPU-rendered trails, curated visual appearance. Evidence: derivative/integration unit tests, screenshot/video of real output, repeatability checks, 20-min performance report on target device.

## M2 — Geometry & Surfaces — ACCEPTED
Deliver: reusable parametric Metal surface renderer, wireframe/shaded representations,
optional 3D coordinate planes/axes/ticks with adjustable density, Wormhole and Torus,
mathematical controls and camera orbit/pan/zoom in the existing floating inspector.
Preserve Lorenz. No universal scene editor, Black–Scholes, KKT, timeline, export or formula editing.
Evidence: formula/normal/seam/validation tests, device rendering checks, real screenshots
at baseline/compact sizes and user visual review. User visual review/acceptance confirmed on 2026-11-02.

The former M2 usability scope (versioned documents, save/load, undo/redo and PNG export)
is deferred to a later explicitly authorized milestone; it is not part of Geometry & Surfaces.

## M3 — Motion & Dynamical Systems

### M3.1 — Geodesic Solver + Torus Geodesics — IMPLEMENTED, REVIEW PENDING
CPU Double metric-derived geodesic equations, deterministic RK4/fixed-step playback,
metric-normalized launch conditions, periodic coordinates, bounded/fading trajectory,
one surface particle, native controls and reuse of the accepted M2 torus renderer/camera.
Evidence: metric/acceleration/constraint tests, actual equatorial circles, restart/pause/step,
extended finite trajectories, measured numerical drift/convergence, device rendering checks
and user review of the actual animation. See [M3.1 evidence](evidence/m3.1-geodesics.md).

M3.1 refinements include live playback/visibility controls and continuous camera following.
They do not change its acceptance status. The subsequent user request separately authorizes M3.2.

### M3.2 — Wormhole Geodesics — IMPLEMENTED, VALIDATION/REVIEW PENDING
User-directed revision: restore the original funnel with a wider square grid and compare
multiple simultaneous starting positions sharing a launch heading and surface speed.
CPU Double RK4 follows the actual funnel's induced metric. Optional lower region, selected
particle follow, bounded history and continuous motion beyond the displayed grid.
Reuse M2 rendering and M3.1 interactions without changing the Torus model. No lensing claims.
Evidence: [full current M3 report](M3_STATUS.md); the earlier Ellis report
is historical. Metal rendering and user animation review remain pending. Not accepted.

### M3.3 — Vector Fields — IMPLEMENTED ON DRAFT STACK, UI PENDING

2026-11-13 roadmap request authorizes the independent/explicitly stacked sequence:
M3.2 verification → UX-01 → M4.1 → M3.3. Four parameterized 2D fields and Euler/RK4
trajectories are implemented on `feature/m3-3-vector-fields`, with numerical/build evidence
in `evidence/m3-3/README.md`. Native-window access blocks visual review; not accepted.

The earlier M3.2-only scope is superseded by the explicitly authorized 2026-11-13 roadmap sequence. Timeline/keyframes,
formula editing, Black–Scholes, KKT, export and project persistence remain outside this slice.

### M3 completion checklist

- M3.1: complete device/animation review and user acceptance of Torus Geodesics.
- M3.2: implement and validate Wormhole Geodesics, including comparison launches and continuous boundary behavior.
- M3.3: implement and validate the Vector Fields slice from the fixed roadmap.
- Across M3: mathematical regression tests, actual Metal/desktop checks, sustained target-device
  performance/memory evidence, native interaction/accessibility checks and user visual approval.

These are the explicitly known M3 slices. No later milestone numbering or scope is changed.

## UX-01 — Library and Workspace — PR 2, REVIEW PENDING

Searchable categorized navigation beside the workspace; existing experiments/live previews retained.
Actual native search/navigation screenshots recorded; compact/full Xcode review pending.

## M4.1 — Optimization Foundations — DRAFT PR 3, UI PENDING

Five objective families, analytic derivatives, safeguarded gradient descent/momentum/Newton,
level sets, trajectories and diagnostics. Explicit stack on UX-01. Numerical/build checks passed;
native window inspection blocked. See `evidence/m4-1/README.md`; no acceptance claim.

## M4 — Optimization foundations (historical outline)
Deliver: function plotting/sampling, contour/surface, start point drag, gradient descent and Newton, step mode and solver metrics, Art/Analysis views. Evidence: solver unit tests on quadratics and Rosenbrock, mathematical annotation checks.

## M5 — Expression editor and advanced optimization
Deliver: restricted user formula grammar, AST validation, solver model integration, constrained optimization experiments and visualizations. Evidence: parser tests, malformed input tests, complexity bounds, solver correctness.

## Exit rule
No milestone is done merely because code was written. It is done when acceptance tests are run, actual screenshots are reviewed, and limitations are recorded. If macOS/Xcode is unavailable to the agent, mark hardware-dependent gates pending and provide exact local verification instructions.
