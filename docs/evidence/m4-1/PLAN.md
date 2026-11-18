# M4.1 bounded slice

Explicit stack on unmerged UX-01 / PR 2; PR base is `feature/ux01-library-workspace`. No merge/main push.

- Pure Double `Objective2D`/sample/iteration-record API; concrete convex, ill-conditioned, Rosenbrock, double-well and saddle objectives.
- Gradient descent, heavy-ball momentum with non-descent restart, shifted-Hessian Newton; Armijo backtracking, finite/domain safety, bounded iteration history and explicit stop states. These are discrete iterations, not ODE time.
- Uniform scalar sampling and triangular piecewise-linear level sets from the same objective definition. Equal-unit x/y plot, tap/numeric starting points, actual objective history and diagnostics. SwiftUI Canvas is sufficient for this bounded 2D slice; existing Metal scenes are preserved.
- Acceptance: finite-difference gradient/Hessian checks, analytic quadratic one-step Newton, convergence of all methods, nonconvex/ill-conditioned Newton, saddle distinction, limits/invalid inputs, sampled level-set checks; release build, native launch and actual interaction/screenshots. Full Xcode/device checks are environment-dependent and reported separately.
- Files: new core Optimization/PlanarAnalysis, new UI session/inspector/plot; existing workspace/commands/scene routing and Xcode membership; tests/evidence/handoff.
- Risks: line-search/regularization semantics must be explicit, nonconvex convergence is local, out-of-view iterates must be labelled rather than clamped, compact layout and Canvas cost need real review. No advanced optimizer extension implemented.
