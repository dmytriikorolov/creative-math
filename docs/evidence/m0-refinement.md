# M0 gallery refinement — 2026-10-30

M0 remains **NOT ACCEPTED**. This is a source review and compiled refinement, pending desktop visual QA.

## Review and changes

- Removed the redundant navigation toolbar title. The native window owns the application title;
  the gallery heading is now “Studies.” Screenshot confirmation is pending.
- Replaced the fixed 400 pt rounded preset card and separate blank-scene column with a larger
  live Metal preview and a quiet detail column. Content is bounded to 1040 pt, with 48 pt margins;
  below 1040 pt window width, content stacks with 24 pt margins and vertical scrolling.
- Preview preserves its 8:5 frame ratio. The preview itself remains actionable through a standard
  plain Button, so opening the study does not require reaching the detail action in a short window.
- Headings use the shared 20 pt title token; supporting sentences use 13 pt body instead of
  11 pt metadata. Geometry values use the shared 12 pt numeric token. Removed future-milestone
  and implementation labels from the gallery/workspace.
- Blank Scene and Restore Placement now use native bordered buttons; Open Study uses a native
  prominent button. Removed the two custom button styles. Native control focus, hover, pressed
  and disabled appearances replace hand-drawn equivalents.
- The renderer, scene identity, inspector drag/keyboard logic, snap thresholds, clamping,
  persistence keys and panel dimensions are unchanged.
- UI tests now retain real window screenshot attachments for gallery, blank workspace, triangle
  workspace and inspector focus when run. Extended the inspector test to check position across
  app termination/relaunch. These additions have **NOT RUN** here.

## Executed verification

- `TMPDIR=/private/tmp/ ./scripts/build-app.sh`: **PASS**, Swift 6 build and ad-hoc app signing.
  See `m0-refinement-build.log`.
- `TMPDIR=/private/tmp/ ./scripts/test.sh`: **PASS**, 3 placement tests, 0 failures.
  See `m0-refinement-tests.log`. This does not exercise SwiftUI interaction or persistence.
- Secondary token contrast, computed from sRGB relative luminance: #AAB1BC on #08090B is
  **9.22:1**; on #14161A is **8.39:1**. These are token-level measurements; actual native
  control text/focus and rendered screenshots still need inspection.

## Attempted desktop checks and limitations

- Full Xcode is still absent; the selected developer directory is Command Line Tools.
  `xcodebuild -project CreativeMath.xcodeproj -scheme CreativeMath -destination 'platform=macOS'
  -derivedDataPath /private/tmp/CreativeMathDerivedData CODE_SIGNING_ALLOWED=NO build test`
  fails before building because `xcodebuild` requires Xcode.
- `open '/private/tmp/creative-math-build/Creative Math.app'` fails with Launch Services
  error -10827. The bundle executable exists and signature verification passes.
- A fresh Core Graphics/Metal probe reports **0 visible windows**, screen capture access
  **false**, and Metal device **unavailable** in this restricted session.
- **VISUAL QA NOT RUN.** No gallery/workspace screenshots could be captured. Triangle rendering,
  navigation, blank-scene clear, inspector interaction/persistence, native focus states and
  responsive composition remain **UNVERIFIED AT RUNTIME**. Build success is not rendering evidence.
- No frame timings or sustained performance claims.

## Required local checks

Use the Xcode build/test command in README from a logged-in macOS desktop session. Inspect UI
screenshot attachments in the test results; these use the actual test window size. Then follow
`m0.md` for captures at exactly 1440×900 and 1280×800 pt. Also check 900×600 pt to exercise the
stacked layout, and 1728×1117 pt where available. Scroll through the narrow gallery and verify
both native scene actions and preview activation.

Check a single application title, preview aspect, readable/wrapping secondary text, native
button hover/press/Tab focus, and no clipping. Verify every inspector edge snap, arrow-key
movement, restore, resize clamping and relaunch persistence. Check VoiceOver and Reduce Motion.
Record defects against actual screenshots before M0 signoff; do not start M1 until these gaps close.
