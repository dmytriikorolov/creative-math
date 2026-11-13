# M0 inspector interactions — 2026-10-30

Status: implemented and compiled; desktop interaction acceptance and visual QA remain pending.
The user confirmed that the previous inspector position persisted across relaunch. New size
persistence has automated preferences coverage but still needs desktop relaunch verification.

## Changes

- Header mouse tracking uses AppKit screen coordinates, avoiding local-coordinate feedback as
  the panel moves. The whole header participates, including padding, except the close button
  and perimeter resize regions. A 3 pt movement threshold separates clicks from drags.
- Eight resize regions: four 6 pt edge strips and four 12 pt corners. The body and buttons have
  no move gesture; the scroll view is inset from right/bottom resize strips so its scrollbar
  remains independent. Header arrow keys still move the panel. VoiceOver actions resize/reset.
- Public macOS frame-resize cursors are used on macOS 15+. macOS 14 uses the public horizontal/
  vertical resize cursors and a system-symbol diagonal cursor fallback. No private APIs.
- Default 304×224 pt, minimum 280×224 pt, maximum 520×640 pt. Workspace bounds override minimum
  dimensions if necessary to keep the panel visible. Opposite resize edges remain fixed.
- Movement uses continuous magnetic attraction inside 12 pt, settling within 3 pt. Both live
  movement and mouse-up use the same initial frame and total translation; there is no separate
  release-time snap. Zones shrink to avoid overlap when the panel nearly fills an axis.
- Position and dimensions save at interaction end. Existing `inspector.x` / `inspector.y` keys
  migrate without losing valid position; new `inspector.width` / `inspector.height` keys store
  dimensions. Invalid/missing values recover to defaults; restored geometry is bounded.
- Double-click the header to restore default dimensions, retaining position where possible.
  Restore Placement moves to the upper right while retaining size. Workspace size changes
  clamp the panel and end any current interaction. Hiding/leaving the workspace saves live edits.
- Renderer unchanged: MetalViewport.swift SHA-1 remains
  `3c1a6b73dd5be4aae0b59dd4d1c2a995bdbf4249`.

## Executed checks

- `TMPDIR=/private/tmp/ ./scripts/test.sh`: **PASS**, 14 Swift Testing test functions, 0 failures.
  Two functions each exercise all eight resize directions. Coverage: drag translation/bounds,
  fixed opposite edges, resize limits, resize translation, continuous/monotonic and symmetric
  magnetic attraction, overlapping-zone prevention, small-workspace clamping/idempotence,
  repeated-drag continuity and direction, invalid geometry recovery, default-size geometry,
  preferences round trip and legacy migration.
  Log: `m0-inspector-tests.log`.
- Preferences tests use isolated UserDefaults suites and a fresh preferences instance in the
  same process. They do not prove OS disk flushing or actual app relaunch behavior.
- `TMPDIR=/private/tmp/ ./scripts/build-app.sh`: **PASS**, Swift 6 app build, bundle and ad-hoc
  signing. Log: `m0-inspector-build.log`. `codesign --verify --strict --verbose=2` also passes.
- Xcode project plist lint and app source membership: **PASS** (static validation).
- UI test Swift syntax parse: **PASS**; full XCTest compilation/execution **NOT RUN**.
- Full `xcodebuild ... build test`: blocked because only Command Line Tools is installed.
- Launch via `open`: fails with Launch Services -10827. Probe reports 0 visible windows,
  screen capture access false and no available Metal device in this restricted session.
- **VISUAL QA NOT RUN.** No actual screenshots or interaction-feel claims. M0 is not accepted.

## Desktop checks required

Run the Xcode command in README. Three UI tests are available, including a new test that resizes
from the lower-left corner, checks fixed opposite edges, scrolls without moving the panel,
relaunches to check position/dimensions, double-clicks to restore size, and closes the panel.
Existing tests cover header dragging, arrow movement, restore placement and scene navigation.
Screenshot attachments will be retained in Xcode test results when tests actually run.

At 1440×900 and 1280×800 pt (also minimum 900×600), manually verify:

1. Drag the icon, text, empty header space and header padding. Confirm a stable pointer grip,
   normal click/double-click behavior, and no drag when pressing Close or body controls.
2. Resize all eight directions, slowly and quickly, up to both size limits. Check edge/corner
   cursor shapes, opposite-edge stability, body readability and scrollbar access.
3. Approach/leave each workspace edge and corner slowly; confirm no release jump or sticky
   escape. Repeat with the panel almost filling workspace height.
4. Scroll inside the body and drag its scrollbar; confirm neither moves/resizes the inspector.
   Exercise Restore Placement and Close/Show after dragging and resizing.
5. Relaunch after moving/resizing. Verify both position and dimensions, then double-click the
   header and verify the default size persists. Shrink the main window and switch displays;
   confirm the entire inspector remains reachable.
6. Check keyboard focus, arrow keys, VoiceOver resize/reset actions, Reduce Motion and
   background/foreground cursor cleanup. Capture focused, resized and snapped panel states.

Next smallest slice: desktop verification/fixes for this interaction model before M1.
