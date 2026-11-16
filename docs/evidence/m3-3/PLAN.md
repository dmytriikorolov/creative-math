# M3.3 bounded slice

Explicit stack on draft M4.1 / PR 3 and UX-01 / PR 2. Neither dependency is approved or merged.

Implement four concrete autonomous 2D fields (oscillator, stable spiral, saddle, Van der Pol) with a validated parameter, normalized direction glyphs and one adjustable trajectory. Pure Double field/integrator types; Euler and RK4, fixed adjustable Δt, bounded history and explicit equilibrium/limit/error states. Preserve every existing experiment.

Reuse PlanarDomain and equal-unit PlanarPlot. Add an optional validated timestep to FixedStepClock; existing calls keep the exact 1/240 default/catch-up behavior. Share only run/pause/step/restart commands through a narrow main-actor planar transport protocol now that two concrete UI consumers exist.

Acceptance: analytic solutions, Euler/RK4 order, render-cadence independence, pause and exact step, nonlinear finite runs, history and safety limits; complete tests/release build, real app launch and visual controls/plot review if the desktop becomes accessible. UI verification blocked on M4.1 is not presumed to have recovered. No performance or visual claims without execution.
