# Ready-PR integration check — 2026-11-13

User authorized merging ready work. PR 1 merged at `252d3fb`. PR 2 was integrated with that main on `feature/ux01-library-workspace`; conflicts were limited to handoff and generated Graphify files. Application source is unchanged from the previously reviewed UX-01 snapshot.

Fresh `TMPDIR=/private/tmp/ CREATIVE_MATH_ARTIFACTS=.../check ./scripts/verify.sh check` **failed**: 98 tests reported, 97 passed, one failure, no Metal skips. Expanded permissions now allow the device tests to execute.

Failure: `ellisRendererModesReuseGeometryAndDrawActualTrajectories()` at `Tests/LorenzMetalTests/WormholeRenderingTests.swift:49`: the rendered image with the rear marker does not exactly equal the surface-only image. This was previously skipped when Metal was unavailable. Whether this is a rendering defect or an incorrect occlusion fixture remains unconfirmed; no assertion was weakened and no speculative shader fix made.

[Full test log](check/tests.log), [workflow result](check/results.txt). The script stopped after the failed tests, so its release/signature stages were NOT RUN in this check. Earlier successful builds are historical evidence only.

PR 2 is held unmerged. Draft PRs 3/4 also remain unmerged with prior native-window/UI verification blockers. M3.2 animation acceptance remains outstanding. Next smallest slice: reproduce and inspect the rear-marker occlusion case on the actual GPU before further feature merges. No application acceptance is implied by merging PR 1's test/documentation-only changes.
