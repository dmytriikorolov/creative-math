# Design system — Computational Minimalism (v0.1)

## Principles
1. **Canvas first:** mathematical imagery is the focal point; UI is subordinate.
2. **Editorial precision:** clear hierarchy, stable alignments, deliberate whitespace, typography that helps read numerical data.
3. **Scientific honesty:** annotations correspond to real values; no fake FPS, trajectories, or labels.
4. **Progressive disclosure:** clean view by default; reveal controls without changing scene state.
5. **Restrained motion:** feedback for state changes, not ambient decorative animation.

## Tokens (starting values, validate on real display)
| Token | Value | Use |
|---|---|---|
| canvas | `#08090B` | primary backdrop |
| surface | `#14161A` | floating panels |
| elevated | `#1C1F24` | menus, active panels |
| border | `#292D34` | separators and panel boundaries |
| text-primary | `#E8EAED` | labels and headings |
| text-secondary | `#AAB1BC` | supporting information |
| accent | `#91A9E8` | selected control, focus, active keyframe |
| error | `#EF8E8E` | invalid formula/error |

Do not assume tokens are accessible merely because they are specified. Measure contrast for actual text sizes and adjust as needed. Rendered art has independent palettes; UI accent is not forced into artwork.

## Typography
Use system SF Pro for UI, SF Mono for numerical values, equations, timing, diagnostics. Define semantic roles rather than scattering arbitrary font sizes: title 20/26, section 13/18 semibold, body 13/18, metadata 11/15, numeric 12/17 mono. Sizes in points; adjust for legibility and accessibility. Avoid all-caps paragraphs; reserve uppercase for sparse metadata.

## Layout
- Primary window baseline: 1440×900 pt; test at 1280×800 and 1728×1117. Respect safe areas and macOS titlebar/traffic lights.
- Use 4-pt spacing scale: 4, 8, 12, 16, 24, 32. Controls at least ~28 pt tall; precision inputs must remain usable.
- Default viewport fills available workspace. Floating inspectors are 280–340 pt wide, compact, and avoid covering central subject when possible.
- Panels drag from the entire header except interactive buttons. Magnetic attraction begins within 12 pt of designated workspace edges, settling within a small contact zone without a release-time jump. Snap to workspace bounds, not physical screen.
- Inspectors resize from edges and corners with macOS resize cursors. Default size: 304×224 pt; minimum 280×224 pt; maximum 520×640 pt. Clamp dimensions and placement to the available workspace, allowing smaller dimensions only when necessary to remain visible. Persist both position and size. Double-click the header to restore default size; Restore Placement keeps the current size.
- Prefer subtle opaque surfaces to heavy blur. Borders 1 px-equivalent, corner radii 8–12 pt for panels, 4–6 pt for controls. Avoid gratuitous shadows.
- Timeline is collapsed/absent in V0.1; future expansion should not require replacing the viewport architecture.

## Components and states
- Numeric field: visible value, unit if applicable, valid range, precise typing, scrubbing optionally; support Enter commit and Escape revert.
- Slider: paired with numeric input; consistent hover/focus/drag/disabled states.
- Floating inspector: header, close/collapse, drag handle, snap feedback, keyboard access, sensible resize behavior.
- Preset tile: actual scene preview (not stock art), descriptive model name, keyboard activation.
- Formula field (later): monospace text, parse error span, clear invalid-state feedback; do not silently mutate invalid formulas.
- Play/pause/reset/step must have unambiguous state and keyboard shortcuts.
- Focus indicator must be visible against both canvas and panels. Support VoiceOver and reduced-motion preferences.

## Motion
- UI transitions typically 120–200 ms; no bouncy spring by default.
- Dragging follows pointer without perceptible animation; snap preview may animate briefly on release.
- Scene simulation motion is distinct from interface motion and obeys pause/reset/scrub controls.
- Respect Reduce Motion for interface animations, not by silently changing mathematical results.

## Art direction
Use precise thin trails, intentional negative space, controlled exposure, crisp geometry, optional restrained bloom. Avoid default neon-rainbow palettes and excessive particles as a substitute for composition. Curate at least three distinct palettes with intentional contrast and clipping behavior.

## Visual QA checklist
Capture actual app screenshots at baseline and compact window sizes, including: gallery, empty scene, attractor clean view, inspector open, inspector snapped, invalid input, keyboard focus. Check clipping, contrast, alignment, panel overlap, text legibility, visual hierarchy, correct macOS chrome, and consistency with reference images. Log defects and fix before milestone signoff. Never claim screenshot review if capture is unavailable.


## M2 surface studies

Use fine, neutral cool parameter curves with hidden-surface removal, opaque restrained
shading only when selected, and no bloom or ambient animation. Coordinate planes are opt-in;
axes use muted red/green/blue, with letters and explicit tick spacing so color is not the
only cue. Surface and coordinate grid densities are independent controls. Reuse the native
numeric fields, camera gestures and floating inspector sizing/snap behavior. Include flat
Wormhole, narrow/deep throat, Torus seams, grid intersections, hovered/focused/invalid controls
and a scrolled inspector in baseline/compact screenshot review. Current styling is provisional
until actual GPU screenshots and user visual review; source code does not establish approval.


## M3.2 spatial wormhole study

Use the existing cool surface material/parameter curves and warm geodesic/particle hierarchy.
The Ellis throat is one smooth shared row between two regions, not two disconnected funnels.
A subtle l=0 circle is an optional mathematical reference. Default framing includes both rims.
Presentation modes change coverage/mesh, not solver state. Opacity uses the nearest sheet as
coverage with depth occlusion; Trajectories explicitly hides that surface for unobstructed paths.
No bloom, lensing imagery, starfield or decorative tunnel motion. Review near-critical winding,
throat crossing, signed-region changes, transparent/hidden modes, follow/camera stability,
invalid launch combinations and the scrolled inspector at baseline/compact/Retina sizes.
