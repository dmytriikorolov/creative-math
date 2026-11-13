# Development workflow

Audited 2026-11-13. See [project status](PROJECT_STATUS.md) and [audit evidence](evidence/audit-2026-11-13/README.md).

## Local loop

Requirements: macOS 14+, Swift 6, Metal-capable desktop; full Xcode for XCTest UI automation. No external Swift packages are declared. From the project root:

```sh
TMPDIR=/private/tmp/ ./scripts/verify.sh check
TMPDIR=/private/tmp/ ./scripts/verify.sh launch
# Full Xcode installation required; override per command without changing system selection:
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/verify.sh xcode
```

`check` sequentially runs Swift Testing, release packaging and strict signature verification. `launch` adds Launch Services open; its success alone does not establish a visible window. `xcode` runs the shared scheme's core, Metal and UI test targets and retains an xcresult bundle. Each run writes logs/results under `docs/evidence/verification-<UTC>-<pid>/`; override with an absolute `CREATIVE_MATH_ARTIFACTS` path. Scripts stop on failure. Read test logs for skipped GPU tests: a green command with skips does not verify Metal.

Existing individual commands:

```sh
TMPDIR=/private/tmp/ ./scripts/test.sh
TMPDIR=/private/tmp/ ./scripts/build-app.sh release
open '/private/tmp/creative-math-build/Creative Math.app'
TMPDIR=/private/tmp/ ./scripts/validate-lorenz.sh --help
```

Do not run builds/tests concurrently against the shared scratch directory. The SwiftPM bundle is ad hoc signed for local testing; it does not reproduce the Xcode sandbox/hardened-runtime configuration or distribution signing. Shaders are compiled from source at runtime; Swift compilation alone does not validate their pipelines.

## Desktop verification

Use supported macOS computer-use tools to select the packaged app by full path, read accessibility state and capture the real window. Inspect at 1440×900 and 1280×800 points; include 1728×1117/Retina when available. Save useful PNGs under the run's `screenshots/` directory; record window size, scale, scene, settings, simulation state and findings in the run README. Screenshots may also be retained as XCTest attachments in xcresult. Never substitute graph previews or generated images.

1. Inspect gallery, Blank Scene and Triangle; open Lorenz Classic/Filament/Sculpture and static Wormhole/Torus. Check for render-failure banners.
2. Check pause, exact single-step, restart, orbit/pan/zoom, inspector scrolling, resize/snap, keyboard focus and invalid input. Compare hierarchy, clipping, contrast and scene occlusion with `design-system.md`.
3. Review Torus motion/follow and Wormhole open/lower/rounded modes. Check simultaneous row, seeded relaunch, survivor preservation, follow waiting/reacquisition and centered trail heads. Pause and restart must retain documented semantics. Check Reduce Motion for camera transitions.
4. Record actual animation observations separately from still screenshots. User animation approval remains required for M3.1/M3.2 acceptance. Measure device/resolution/frame times before performance claims.

If app selection, capture, Accessibility or Screen Recording fails, record the exact error and mark VISUAL QA NOT RUN. Do not change privacy permissions silently. Full Xcode and an accessible logged-in Metal desktop are prerequisites for the complete loop; command-line success is only part of validation.

## Git and GitHub

This delivered folder has no `.git` metadata. Do not invent history, initialize a replacement repository, guess a remote or publish this copy. Resume Git work in the user's genuine checkout (or after its original metadata is restored).

Before editing there, inspect `git status --short --branch`, `git log -6 --oneline`, `git remote -v`, and existing local author identity. Preserve unrelated changes and existing identity. Start a bounded `feature/<scope>` branch from the appropriate stable `main` baseline; never work or push directly on `main`. Stage explicit files and create descriptive commits after checks. Do not force-push, reset user work or rewrite history.

When publication is explicitly authorized, push the feature branch and create a PR through the authenticated GitHub connector or existing CLI authentication. Never print credentials. PRs target `main` and describe behavior/scope, executed commands and results, screenshot links/attachments, skipped checks and known limits. No AI co-author trailers unless repository policy requires them. Never merge without explicit user approval. No remote changes were made during this audit.

## Handoff and graph

Read `docs/STATUS.md` first; update it after meaningful work. Keep current confirmed facts in `PROJECT_STATUS.md`, detailed results in `docs/evidence/`, and distinguish historical acceptance from fresh execution. Use graph traversal for module relationships, then inspect source for exact behavior.

```sh
graphify explain SurfaceMotionSession
graphify query 'WormholeSession camera' --budget 1200
graphify update .
```

The graph update is local code extraction; it does not establish semantic documentation freshness. No LLM labeling or external semantic extraction is required for this workflow. Do not install global hooks/configuration merely to refresh the graph.
