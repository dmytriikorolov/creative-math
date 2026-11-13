# M3.2 verification and stabilization

2026-11-13. Branch `feature/m3-2-stabilization`, approved base `961bf61`.

## Scope and findings

Reviewed concrete open/rounded solvers, bounded comparison pools, seeded stream, display interpolation, selected-slot follow policy, viewport and runtime Metal passes. No reproducible numerical or lifecycle defect was found in this pass; no speculative solver/shader change was made.

Added a maximum-size 17-slot regression over 96 simulation units for open and rounded geometry and seeds 0/42/999999 at full launch variation. It requires actual repeated recycling, finite bounded histories, small energy drift, independent rounded runs matching exactly and open restart reproducing every state/generation. Existing tests cover cadence independence, survivor preservation, exact initial rows, boundary retirement, numerical derivatives/convergence, shape extremes and waiting/returning camera policy.

## Executed evidence

- `TMPDIR=/private/tmp/ CREATIVE_MATH_ARTIFACTS=.../check ./scripts/verify.sh check`: 98 reported tests; 90 passed, eight Metal checks skipped (device unavailable in shell), zero failures. New stress test passed in 14.803 s. [Tests](check/tests.log).
- Release packaging/signature: see [results](check/results.txt), [build](check/build.log). No application source changed from the baseline inspected on desktop.
- Full Xcode/UI test suite NOT RUN: only Command Line Tools selected. No current sustained frame-time claim.
- Actual app selected via native Computer Use. Opened Wormhole, restarted, enabled follow, set 16×, resumed. Multiple balls and differing trajectories observed. A later frame showed the selected ball approaching again with follow still enabled after earlier deflection, consistent with recycling; this is sampled observation, not proof of smooth reacquisition throughout.
- Paused, reset camera and switched Surface → Trajectories. Surface geometry disappears while the same paths remain; opacity control is removed. No render-failure banner or crash observed. Saved [follow later](screenshots/follow-later.jpg), [surface](screenshots/surface.jpg), [trajectories](screenshots/trajectories.jpg). Captures 2880×1800 pixels; default 1440×900 points at 2× inferred, not independently measured.

## Acceptance limits

M3.2 is **not accepted**. Human review of actual animation remains required. Waiting/reacquisition timing and Reduce Motion are unit-tested but not continuously recorded visually here. Exact compact sizing, all invalid controls, sustained device profiling and GPU parity/depth assertions remain pending. Prior rounded-return grid kinks need dedicated visual comparison; this pass does not certify or fix them. The screenshots establish functioning modes and live output, not complete animation acceptance.
