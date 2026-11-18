# UX-01 Library and Workspace

2026-11-13. Independent `feature/ux01-library-workspace` branch from approved main `961bf61`; does not include or depend on unmerged PR 1.

Plan/implementation: add a compact native Library beside the existing workspace, case/diacritic-insensitive multiword experiment search, Dynamical systems/Geometry categories, selected-study indication, empty-result recovery and keyboard access (⌘L, ⇧⌘L). Keep every existing solver/renderer/inspector and live preview. Library navigation reuses session objects; hide/show preserves the current scene and simulation state. Static surface entries select the requested surface; existing Lorenz appearance controls remain.

Files: WorkspaceView, UI interaction tests and documentation. No new dependency, target or source membership.

## Verification

- `verify.sh check`: 97 reported tests, 89 passed, eight Metal skips, zero failures; release packaging/signature passed. [Results](check/results.txt).
- After accessibility/focus fixes: release rebuilt successfully ([log](rebuild.log)); `swiftc -frontend -parse UITests/WorkspaceUITests.swift` and project plist lint passed. Full Xcode/UI suite NOT RUN (CLT only); new UI test covers search, navigation, empty recovery and preserved paused state.
- Actual rebuilt app launched with native Computer Use. Searched “torus”: only Torus geodesics and surface entries remain. Opened Torus motion directly; verified collapse of Library, no-results message and Clear filters recovery. Final rebuild exposes distinct stable accessibility identifiers (container inheritance bug fixed), opens static Torus, clears search focus on entry navigation and renders real geometry without a failure banner.
- [Search](screenshots/search-torus.jpg), [motion workspace](screenshots/torus-workspace.jpg), [final static Torus](screenshots/final-static-torus.jpg). The first two precede the identifier/focus-only fix; final image is from the final build. 2880×1800 pixels, default 1440×900 point/2× inferred.
- Native coordinate resize returned `-10005 noWindowsAvailable`; bundle-ID reselection recovered. Exact 1280×800 capture NOT VERIFIED. No fake compact screenshot. Normal, selected and empty states inspected; full keyboard/VoiceOver/Reduce Motion review remains pending. No new interface animation was introduced.

Known limits: search filters the navigation list, not the legacy live-preview gallery. The library can be collapsed to reclaim canvas width. Compact-window acceptance remains outstanding; this PR is not a claim of milestone visual acceptance.
