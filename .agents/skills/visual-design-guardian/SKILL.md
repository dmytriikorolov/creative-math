---
name: visual-design-guardian
description: Use when implementing or reviewing any SwiftUI workspace, panel, gallery, control, or UI motion; requires screenshot-based visual QA against the project's design system.
---
# Visual Design Guardian
1. Read `docs/design-system.md` and identify which component/state is changing.
2. Enumerate normal, hover, focused, disabled, invalid, compact-window and Reduce Motion cases where relevant.
3. Implement using shared tokens and semantic typography. No generic dashboard/card-heavy styling, random gradients, or arbitrary font sizes.
4. Build and launch the real macOS app. Capture screenshots at 1440×900 and 1280×800; include focused/invalid and snapped-panel states when affected.
5. Compare: hierarchy, alignment, 4-pt rhythm, text clipping, contrast, occlusion of central scene, panel snapping, window chrome, keyboard navigation.
6. Record each issue with severity and screenshot evidence; fix high-severity defects before calling done.
7. If screenshots cannot be captured, say **VISUAL QA NOT RUN**, explain why, and give local verification steps. Never fabricate screenshot evidence.
