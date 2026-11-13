# Repository/workflow audit — 2026-11-13

Scope: source/tooling audit, local verification and development instructions. No application/model/shader code changed and no later feature implemented. Host: arm64, macOS 26.5.1 (25F80), Apple Swift 6.3.3; selected developer directory `/Library/Developer/CommandLineTools`.

## Executed checks

| Command/check | Result |
|---|---|
| `git status --short --branch` | Exit 128: not a Git repository. No `.git` in this directory or parents; history/remotes unavailable |
| `TMPDIR=/private/tmp/ ./scripts/test.sh` | Exit 0; 97 reported, 89 passed / eight GPU checks skipped, no failures; test execution 5.471 s, initial build 112.09 s. [Log](tests.log) |
| `TMPDIR=/private/tmp/ ./scripts/build-app.sh release` | Exit 0, cached release build 0.26 s, local app bundle signed. Initially waited for the test scratch lock. [Log](build.log) |
| `codesign --verify --deep --strict '/private/tmp/creative-math-build/Creative Math.app'` | Exit 0, no diagnostics. [Log](signature.log) |
| `xcodebuild -project CreativeMath.xcodeproj -scheme CreativeMath -destination 'platform=macOS' build test` | Exit 1, requires full Xcode; selected CLT. Xcode build/UI tests NOT RUN. [Log](xcode.log) |
| `plutil -lint CreativeMath.xcodeproj/project.pbxproj` | Passed. [Log](project-lint.log) |
| `zsh -n scripts/verify.sh scripts/test.sh scripts/build-app.sh` | Exit 0 |
| `./scripts/verify.sh invalid` | Expected exit 2 and usage text. [Log](verify-usage.log) |

Metal tests report device unavailable in the shell execution context. This does not contradict visible Metal rendering in the desktop process; GPU parity/depth/resource assertions remain unverified. No performance benchmark was performed.

## Actual desktop inspection

Used supported `cua_repl` native app tools. Display-name selection initially failed (`Invalid app`); first full-path selection timed out. Retrying the packaged full path succeeded with the Creative Math window and accessibility tree. A later action returned `-10005 noWindowsAvailable`; inventory showed the app still running and selection by `dev.creativemath.CreativeMath` recovered. No persistent app crash was observed; the transient failure's cause is unconfirmed.

Actual window screenshots saved as native JPEG bytes (2880×1800 pixels). This is consistent with the app's default 1440×900 point window at 2× scale; explicit point-size/scale measurement was not exposed in the observed accessibility tree, so exact sizing remains inferred.

- [Gallery](screenshots/gallery.jpg): Studies/Lorenz preview renders, clear hierarchy and readable text; lower studies require scrolling by design.
- [Torus paused](screenshots/torus-paused.jpg): visible wireframe and amber trajectory, legible floating inspector, central object not obscured. Pause became Resume and enabled Step. Step/Restart clicks and return to gallery succeeded after reconnection; exact numerical delta was not measured through UI.
- [Wormhole paused](screenshots/wormhole-paused.jpg): two-sheet funnel, 13-ball row/trails visible, seed 42, variation 0.5, continuous and simultaneous-row defaults visible. Pause became Resume and enabled Step.
- [Rounded return](screenshots/wormhole-rounded.jpg): toggle updates actual surface and disables lower-sheet hiding. Inspector scrolls to the control. Minor grid kinks are visible near the right-hand return (lower-right image); classification/root cause needs a dedicated camera/mesh regression capture. No shader change was attempted without targeted acceptance evidence. The inspector partly covers that return, so this is not complete silhouette approval.

Returned rounded mode off and left the app in the gallery. No render-failure banner appeared in inspected states. This is **partial visual smoke verification**, not complete milestone QA. Compact 1280×800, independently measured sizing, focus/invalid states, snap/resize, Reduce Motion, sustained animation, follow/relaunch transitions, all presets and GPU assertions remain pending. An attempted action sequence including resize failed with the transient window error before a compact capture; no compact success is claimed. M3.1/M3.2 user animation approval remains outstanding.

## Graph evidence

Existing graph was dated 2026-11-03; no new graph initialization was needed. Ran `graphify check-update .`, `graphify update .`, and `graphify explain SurfaceMotionSession`. [Update log](graph-update.log), [traversal](graph-traversal.log). Initial refresh produced 950 nodes / 2,304 edges / 49 communities. Local extraction only, no paid LLM labeling. Shader string contents are not fully modeled (SurfaceShaders.swift yielded no symbols); docs were inspected directly. No Git commit freshness can be established in this snapshot. Run `graphify explain WormholeSession` or `graphify query 'SurfaceMotionSession camera'` next.

## Workflow script verification

`CREATIVE_MATH_ARTIFACTS="$PWD/docs/evidence/audit-2026-11-13/workflow-check" TMPDIR=/private/tmp/ ./scripts/verify.sh check` exited 0: tests, build and signature passed. See [results](workflow-check/results.txt) and retained component logs. The test log still records eight Metal skips.

`CREATIVE_MATH_ARTIFACTS="$PWD/docs/evidence/audit-2026-11-13/workflow-xcode" ./scripts/verify.sh xcode` exited 1 as expected on this host, preserving [failure results](workflow-xcode/results.txt) and the Xcode diagnostic. This verifies failure propagation; it does not verify Xcode execution. `launch` wraps the existing `open` command; the app was launched independently through native computer use, not through this script mode.

Final `graphify update .` after script changes produced **954 nodes / 2,308 edges / 55 communities**. See [final update log](graph-final-update.log); semantic labels were not refreshed. Unsupported logs/project formats and embedded shader strings remain outside graph coverage.
