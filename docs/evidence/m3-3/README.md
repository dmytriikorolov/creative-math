# M3.3 Vector Fields — draft, visual verification blocked

2026-11-13. `feature/m3-3-vector-fields`, explicitly stacked on draft [M4.1 / PR 3](https://github.com/dmytriikorolov/creative-math/pull/3), which depends on UX-01 / PR 2. No dependency is silently approved. [Plan](PLAN.md).

## Implemented

Pure Double autonomous 2D fields: harmonic oscillator, stable spiral, linear saddle and Van der Pol, each with validated μ ∈ [0,4] and an explicit equation. Dimensionless x/y/time. Euler (first order) and RK4 (fourth order); fixed Δt ∈ [0.0001,0.05], configured step limit ≤20,000 and bounded history. Non-finite/out-of-safety-domain candidates (|coordinate| >10,000) stop with the last valid state; no clamping, reseeding or renormalization. Exact equilibria and step limits have separate statuses.

Clock reuse adds a validated optional timestep; existing calls retain exactly the 1/240 default and 64-step catch-up cap. Render elapsed time drives an accumulator, never the integrator dt; discarded time is exposed. Pause/resume starts a new UI wall-time anchor; Step is one exact dt. Integration continues outside displayed [-4,4]² until the explicit mathematical/safety limit; the plot warns and clips only the drawing.

Native phase-plane workspace, normalized direction-only arrows, equilibrium glyphs, trajectory/start/current markers, numeric/tap initial conditions, parameter/integrator/step controls, diagnostics and shared transport shortcuts. Reuses M4's equal-unit PlanarPlot/PlanarDomain. A narrow main-actor transport protocol serves the two concrete planar experiments; solvers remain independent of SwiftUI/Metal. No dependency or advanced extension added.

## Executed verification

- `TMPDIR=/private/tmp/ CREATIVE_MATH_ARTIFACTS=.../check ./scripts/verify.sh check`: **106 reported, 98 passed/eight existing Metal skips, zero failures**. Release packaging and strict signature passed. [Results](check/results.txt), [tests](check/tests.log), [build](check/build.log).
- New checks: oscillator analytic solution and Euler/RK4 convergence ratios; stable-spiral/saddle analytic trajectories; exact equilibria; render-cadence equality over 1,000 custom-dt steps; pause/exact step and bounded catch-up; 10,000-step nonlinear runs at μ=0/1/4; bounded history; unsafe candidate retention; invalid step/start rejection. Existing clock/Lorenz/Torus/Wormhole tests still pass.
- [Project plist lint](project-lint.log) and diff check passed. Full Xcode/UI suite NOT RUN (CLT only); no current device-performance claim.
- After the built app was packaged, reset native computer-use runtime and selected the exact app path: still `-10005 cgWindowNotFound`. The existing documented `open` command returned 0 ([log](launch.log)), insufficient to prove visibility.

**VISUAL QA NOT RUN for M3.3. No screenshot or animation claim.** Keep draft pending actual field/integrator selection, start placement, direction orientation, pause/step/restart, diagnostics and compact/baseline review. Open Library → Vector Fields; compare oscillator Euler/RK4 at decreasing Δt, then spiral/saddle/Van der Pol; verify clipped-trajectory and numerical-limit messages. Also visually regress the stacked Optimization workspace and all existing Metal studies before acceptance.

Known shared limitations: native window access currently blocks both new planar UIs; exact compact captures and VoiceOver/keyboard pass remain outstanding; existing full XCTest selectors need validation with the new sidebar (global first-scroll-view queries may now target the library). No success is inferred from compile-only UI coverage.
