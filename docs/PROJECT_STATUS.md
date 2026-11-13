# Project status

Audit date: 2026-11-13. Source inspection and fresh execution take precedence over historical plans. Detailed results: [audit evidence](evidence/audit-2026-11-13/README.md).

## Confirmed implementation

- Swift 6 / macOS 14+ native application; SwiftUI shell, AppKit/MTKView bridge, Metal drawing/compute. SwiftPM and a shared Xcode scheme; no external package dependencies.
- `WorkspaceCore`: pure Double models, validated parameters, RK4, fixed-step clock, bounded trails, surface meshes, camera and panel-placement policies.
- `LorenzMetal`: Float32 GPU Lorenz integration and line/ribbon trails; `SurfaceMetal`: shared surfaces, coordinates, geodesic overlays and resource caches. Runtime shader compilation requires device validation.
- `CreativeMath`: Studies gallery, blank/triangle entries, Lorenz presets, static Torus/Wormhole, floating inspectors and transport/camera controls. Panel preferences persist; complete scene documents do not.
- M3.1: concrete Torus metric solver, transport, diagnostics, trail and follow.
- M3.2: open-funnel comparison plus optional rounded +X return, lower sheet, bounded multiple tracks, deterministic continuous relaunch and follow reacquisition. Ellis reference code remains; describing the active experiment as Ellis-only is stale.

## Milestones and unfinished work

| Scope | Confirmed status |
|---|---|
| M0–M2 | Historical user acceptance recorded 2026-11-02; preserved, not newly visually certified by this audit |
| M3.1 / M3.2 | Implemented; desktop/GPU verification and actual animation review remain acceptance gates |
| UX-01 Library / Workspace | Implemented on independent feature branch: search/categories/direct navigation; desktop smoke verified, compact/Xcode review pending |
| M4.1 Optimization Foundations | Implemented on explicit UX-01 stack; numerical/build checks passed, draft pending actual UI verification |
| M3.3 Vector Fields | Not started; deferred |

Scene save/load, undo/redo, PNG/video export, expression AST/editor and timeline remain deferred. Do not interpret architectural proposals as delivered functionality.

## Verification and blockers

Fresh SwiftPM run: 97 reported, 89 passed, eight Metal skips, zero failures. Release packaging and strict signature verification passed. Actual app launch and partial gallery/Torus/Wormhole screenshot review succeeded after retry; compact and full animation/accessibility review remain pending. Minor rounded-return grid kinks are recorded for targeted follow-up. See the audit evidence for commands/results. This directory is a source snapshot without `.git`; status, commits, remotes, feature branches and PR creation cannot be verified here. No Git configuration was changed and nothing was published. Full Xcode is absent from `/Applications` and the selected developer directory is Command Line Tools; Xcode build/UI tests are blocked. Visible desktop verification must be reported separately from SwiftPM compilation.

Existing checks cover model equations/convergence/invariants, deterministic playback/relaunch, geometry, panel placement, GPU/reference/render behavior and XCTest interaction screenshots. SwiftPM runs core/Metal Swift Testing targets; UI tests require the Xcode scheme. GPU tests can skip when no device exists; skipped checks are outstanding coverage.

## Technical debt and priorities

1. **Next slice: M3 validation closure.** Run current core/Metal tests and review actual Torus/Wormhole animation on an accessible desktop, capture baseline/compact evidence, then fix only reproducible defects. Obtain user animation approval before acceptance.
2. **UX-01 next product feature:** agree a small Library/workspace navigation slice preserving all current studies, transport and inspector state. Establish screenshot/keyboard criteria before changing layout.
3. **M4.1:** define a pure 2D objective and typed iteration record; start with a quadratic and gradient descent, then Rosenbrock and robust Newton steps with explicit failure statuses. Validate derivatives/convergence before adding UI. Keep fixed milestone numbering.
4. **Deferred M3.3:** specify one vector field and clear integration/visualization gates after those priorities, unless user priorities change.

Documentation mixes initial architecture proposals with later implementation appendices; the product vision's Ellis-only active description is outdated. SwiftPM/Xcode source lists and signing configurations require parity checks when files change. Sustained current-device performance, accessibility and compact/Retina visual evidence remain incomplete.

Reuse validated parameters, `FixedStepClock`, bounded history, camera policies and typed render snapshots where semantics match. Optimization should produce iteration records (point/value/gradient norm/status); geodesics retain time-based states and metric-specific invariants. Add a small shared value/protocol only after two concrete consumers need it. Do not force optimization iterations into physical timesteps or expand `SurfaceMotionSession` into a universal solver engine.
