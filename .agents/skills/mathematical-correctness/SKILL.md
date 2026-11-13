---
name: mathematical-correctness
description: Use for mathematical models, ODE integrators, optimization algorithms, expression evaluation, and analysis annotations.
---
# Mathematical Correctness
1. State the mathematical model, assumptions, domain, units, initial conditions, precision and stopping criteria.
2. Keep model/solver code independent of SwiftUI and Metal. Use pure, testable functions where possible.
3. Test derivatives and solver steps against analytically solvable cases or trusted independently computed references. Include boundary/invalid inputs and NaN/Inf handling.
4. For ODEs: test convergence order where applicable, timestep sensitivity, and short-horizon reference trajectories. Chaotic systems do not promise long-horizon trajectory equality.
5. For optimization: record objective, gradient norm, step size, iteration count and termination reason. Check on convex quadratic, ill-conditioned problem and nonconvex example.
6. For plots: label slices/projections honestly; sampled contours and solver trajectories must come from the same function definition.
7. Document numerical tolerances and any trade-off between visual speed and numerical fidelity.
