# Project handoff

Last updated: 2026-11-13. Read this first; then consult task-relevant source and linked
evidence rather than rescanning the project. Required project/skill reads in AGENTS.md
still apply. Update after meaningful work with changes, verification, issues and next step.

## Integration — 2026-11-13

User authorized merging ready work. PR 1 (M3.2 verification) merged to main at `252d3fb`; UX-01 / PR 2 now integrates that main without changing application source. Conflicts were limited to handoff and generated graph artifacts; handoff reconciled and graph regenerated. Fresh combined validation FAILED: 97 passed/one Metal rear-marker occlusion failure, no skips. Expanded permissions now run GPU tests formerly skipped. Build/signature stages were not run after the test failure. [Evidence](evidence/ready-pr-integration/README.md). PR 2 is now draft and held unmerged.

M3.2 remains subject to user animation acceptance. UX-01 retains earlier actual search/navigation screenshots and known compact/Xcode limitations. Draft PR 3 (Optimization) and draft PR 4 (Vector Fields) remain unmerged because their actual UI verification is blocked by `cgWindowNotFound`. Do not treat their tested numeric code as accepted UI.

Current working checkout is the original repository; filesystem/Git/network access now works. Next safe action: inspect the GPU rear-marker occlusion failure before merging PR 2; sync local main to merged PR 1 only. See [progress](AUTONOMOUS_PROGRESS.md).


## Audit and autonomous workflow — 2026-11-13

- Added [confirmed project status](PROJECT_STATUS.md), [development workflow](DEVELOPMENT_WORKFLOW.md), concise repository-grounded AGENTS.md and `scripts/verify.sh` (`check`, `launch`, `xcode`). No application behavior changed.
- Fresh Swift Testing run: 97 reported, 89 passed, eight Metal skips, zero failures. Release bundle/signature passed. Full Xcode build/UI suite blocked by CLT-only installation. [Audit logs and screenshot review](evidence/audit-2026-11-13/README.md).
- **Actual app launch and partial visual inspection succeeded** through native computer use after retry. Gallery, paused Torus, paused Wormhole and rounded-return screenshots are retained. This supersedes older “VISUAL QA NOT RUN” statements only for these smoke checks. Compact/focus/accessibility/animation/performance gates remain pending; M3.1/M3.2 are not accepted.
- Computer use had a launch timeout and one transient `noWindowsAvailable` failure; bundle-ID reselection recovered. Exact window point sizing is inferred from default/2880×1800 pixel captures, not independently measured. Minor rounded-return grid kinks need targeted review; no visual fix is claimed.
- No `.git` metadata: branch/history/remote/commit/PR operations blocked. Did not initialize a replacement, change identity or publish. Resume in the genuine checkout.
- Existing Graphify graph refreshed with local extraction; use graph traversal then exact source inspection. Semantic doc freshness and commit match are not established.
- Next smallest slice: targeted M3 desktop/GPU validation and animation review, including return-grid artifact; then UX-01 as the next product feature. M4.1 and deferred M3.3 remain unimplemented.

## Previous handoff (historical; audit above takes precedence)

## Current state

- Quick launch: double-click `Open Creative Math.command` in the project root to
  incrementally build release and open it; README includes Dock access instructions.
  Shell syntax, release build (82.33 s) and strict signature verification passed.
  Launch Services still returns -10827 in this session; desktop launch is unverified.
  No simulation/UI behavior changed. Next launcher check: double-click from Finder
  on the user's logged-in desktop.
- **M0–M2 accepted** by the user on 2026-11-02: native app foundation, Lorenz,
  static Wormhole/Torus surfaces and floating inspectors.
- **M3.1 Torus Geodesics implemented; animation approval pending.** Fixed-step RK4,
  bounded trails, transport and follow. [Evidence](evidence/m3.1-geodesics.md).
- **M3.2 Wormhole is active and not accepted.** Original funnel, 72-unit square field,
  optional lower sheet and selected-ball follow. The user rejected the earlier narrow
  and then wider quartic connector as too angular; do not treat either as approved.
- **Latest revision:** near-semicircular return with a C4 approach blend, more angular
  mesh samples, and grid spacing around the turn. Latest side-grid refinement stores
  its angle at vertices rather than amplifying interpolated Float x near the tangent. Enable Rounded return edge (+X) to
  see it (open funnel remains default). Ball and trail head now share the same center.
- **Continuous launches default on at 2×**, variation 0.5, seed 42. **Start together
  as a row defaults on**: the exact first row launches simultaneously without jitter;
  escaped slots relaunch every two simulation units after a delay. Turn Start together
  off to stagger the first row as well. Surviving
  balls are never replaced. Pool is bounded by selected count (default 13, max 17).
  If all slots remain on the surface, launches wait while existing motion continues.
  Turn continuous off for the simultaneous comparison. Restart repeats the seed.
- Balls/trails disappear four units beyond open edges. **Follow now stays enabled across
  disappearance/relaunch**: hold last camera target and show waiting text, then reacquire
  with a 0.6-second camera transition. Active selection follows immediately; Reduce Motion
  skips the animation. Pause freezes return progress. Torus follow is unchanged.
  Solvers stay deterministic under documented precision/compiler assumptions.
- **M3.3+ not started.** Persistence, undo/redo, export, formula editing and optimization
  remain deferred. Preserve Torus/Lorenz/static M2 behavior.

## Latest verification

[Full shareable M3 capabilities report](M3_STATUS.md).
[Latest follow implementation and checks](evidence/m3.2-follow-relaunch.md).
Executed for the 2026-11-04 revision:
- `TMPDIR=/private/tmp/ ./scripts/test.sh`: 97 total, 89 passed, eight Metal skipped,
  zero failures; 5.748 s test execution.
- Release packaging passed in 45.16 s; strict code-signature verification passed.
- UI test source parsing and Xcode project plist lint passed. No new source files.
- Full Xcode build/UI automation NOT RUN (Command Line Tools only).
- App launch attempted: Launch Services -10827. **VISUAL QA NOT RUN**; Metal execution,
  screenshots, actual animation, frame timing and user animation approval remain pending.

Historical model/verification records: [comparison](evidence/m3.2-comparison.md),
[first rounded edge](evidence/m3.2-rounded-edge.md), [wider quartic](evidence/m3.2-wider-return.md).
Some older project docs still describe Ellis-only motion or earlier defaults; use the
current report/source for the active revision. This workspace has no .git directory.

## Next smallest slice

Review the revised side-grid and simultaneous-row/continuous animation on the user's Mac. Check the
silhouette/grid, centered trails, seeded relaunches, surviving tracks, follow, pause/step
and restart; recheck Torus/Lorenz. Capture actual screenshots at 1440×900 and 1280×800
and measure frame timing before performance claims. M3.1/M3.2 need user animation approval.

```sh
TMPDIR=/private/tmp/ ./scripts/test.sh
TMPDIR=/private/tmp/ ./scripts/build-app.sh release
open '/private/tmp/creative-math-build/Creative Math.app'
```

README has the full Xcode build/test command. Current logs are at
`/private/tmp/wormhole-follow-{tests,build}.log`.

## Relevant files

- Math/playback: Sources/WorkspaceCore/{RoundedWormhole,WormholeComparison,EllisWormhole}.swift
- Mesh: Sources/WorkspaceCore/ParametricSurface.swift
- UI/state: Sources/CreativeMath/{WormholeSession,WormholeInspector}.swift
- Rendering: Sources/SurfaceMetal/{SurfaceRenderer,SurfaceShaders,GeodesicTrails}.swift
- Tests: Tests/WorkspaceCoreTests/WormholeComparisonTests.swift,
  Tests/LorenzMetalTests/WormholeRenderingTests.swift, UITests/WorkspaceUITests.swift
