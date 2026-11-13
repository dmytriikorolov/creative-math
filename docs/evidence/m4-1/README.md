# M4.1 Optimization Foundations — draft, visual verification blocked

2026-11-13. `feature/m4-1-optimization`, explicitly stacked on unmerged [UX-01 / PR 2](https://github.com/dmytriikorolov/creative-math/pull/2). No merge or acceptance implied. [Bounded plan](PLAN.md).

## Implemented

Pure Double `Objective2D`, exact analytic samples (value/gradient/symmetric Hessian), bounded typed iteration records and explicit termination states. Presets: convex and condition-number-100 quadratics, Rosenbrock, double well and an unbounded saddle. Mathematical coordinates/values are dimensionless.

Gradient descent, heavy-ball momentum and Newton use Armijo sufficient decrease (`c=1e-4`, up to 48 halvings). Momentum uses the previous accepted displacement and restarts non-descent directions. Newton shifts the minimum Hessian eigenvalue to at least 1e-4 and falls back to steepest descent if needed. This is safeguarded local optimization, not a global-minimum guarantee. Records include actual step coefficient, gradient norm, iteration and Hessian shift. Gradient tolerance is labelled as such; a stationary negative-curvature point is reported separately. Numerical coordinates are bounded by 1e6; iteration history by the configured limit plus the initial record (maximum 20,001). Out-of-plot iterates are labelled and clipped visually, never clamped mathematically.

Sampled scalar cells and 12 piecewise-linear level sets use the same objective definition as the solver. Equal-unit 2D coordinates, numeric/tap starting points, objective history, diagnostics, run/pause/step/restart and shared simulation shortcuts. All existing Metal experiments preserved. A small domain/mapping and objective protocol support future concrete consumers; no mirror descent, gradient-flow or learned optimizer implemented.

## Executed checks

- [Final verification](final-check/results.txt): 102 tests reported; 94 passed/eight existing Metal skips, zero failures; release packaging and strict signature passed. [Tests](final-check/tests.log), [build](final-check/build.log).
- Tests check gradients/Hessians with independent central differences, all three methods on a quadratic, one-step analytic Newton, ill-conditioned/nonconvex/Rosenbrock Newton convergence, Hessian regularization, saddle classification, Armijo decrease, trace/iteration limits, invalid inputs and level-set error/domain bounds.
- Project plist lint and diff whitespace check passed. Full Xcode/UI suite NOT RUN (CLT environment).
- First release attempt [failed](check/build.log) because command-wiring source changed during compilation; retained honestly. Final run used frozen sources and passed.
- Native Computer Use repeatedly returned `-10005 cgWindowNotFound` for bundle ID and full packaged path, despite the app inventory listing it running. Reselect/quit/reopen attempts failed to recover a capturable window. Existing launch command `open ...` returned 0 ([log](launch.log)), which does not prove visible UI. No matching CreativeMath crash report found in the accessible DiagnosticReports directory; cause remains unconfirmed.

**VISUAL QA NOT RUN for M4.1. No new screenshots or animation acceptance claimed.** This PR remains a draft until the actual rebuilt Objective/Method controls, plot interaction, convergence display, keyboard/focus, invalid states and baseline/compact layout can be inspected. Open the packaged app on an accessible desktop, select Library → Optimization Lab, test all methods/objectives, click/numerically edit starts, pause/step/restart and capture 1440×900 / 1280×800. Profile Canvas on the target device before performance claims.
