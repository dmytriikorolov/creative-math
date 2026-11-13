# Creative Math — working agreement

## Scope and handoff
- Read `docs/STATUS.md` first, then `PROJECT_STATUS.md`, product vision, design system, architecture, roadmap and task-relevant `.agents/skills/*/SKILL.md`.
- Work on one milestone and one small vertical slice. State intended files, acceptance checks and risks before editing. Preserve unrelated user changes and existing functionality; inspect conventions first.
- Update `docs/STATUS.md` after meaningful work; keep detailed commands/results/screenshots in `docs/evidence/<run>/`. Distinguish historical acceptance, source inspection and fresh execution.
- M0–M2 were user-accepted on 2026-11-02. M3.1 Torus and M3.2 Wormhole are implemented but still need user review of actual animation. Active Wormhole is open-funnel comparison with optional rounded +X return; Ellis reference code also exists. Preserve Lorenz, Torus and static surfaces.
- Keep M0–M8 numbering. UX-01, M4.1 and deferred M3.3 need their own bounded scope; do not implement them as cleanup. Scene persistence, undo/redo, export, timeline and expression editing are deferred.

## Architecture and conventions
- Native macOS 14+, Swift 6, SwiftUI/Observation, AppKit/MTKView and Metal Shading Language. No external Swift packages. Prefer existing dependencies; no C++ without measured need and user approval.
- `WorkspaceCore`: pure Double math, validated parameters, solvers, bounded history, geometry, camera and placement policies. No SwiftUI or Metal dependencies.
- `LorenzMetal`: Float32 GPU RK4 and trails. `SurfaceMetal`: mesh/grid/trajectory rendering and resource caches. `CreativeMath`: main-actor UI/session adapters; renderer consumes typed state/buffers.
- Match nearby Swift naming/layout, explicit validation/errors and actor isolation. Keep Package.swift and Xcode source membership consistent when adding files.
- Explore/Create/Analyze are views of shared state. Do not add a node editor, plugin framework, scripting engine, universal solver engine or cross-platform layer speculatively.

## Mathematical and rendering correctness
- Fixed-step integration, capped catch-up; never use frame duration as solver dt. Keep simulation time separate from wall time. Preserve pause, exact single-step and seeded restart.
- Validate inputs and finite states. Test equations, derivatives, invariants, convergence and repeatability as relevant. Do not conceal numerical drift with silent projection/clamping/renormalization. Presentation corrections must remain separate from solver state.
- Document hardware/compiler/precision assumptions; never promise cross-device bit-identical chaos.
- Reuse bounded GPU resources. Avoid per-frame readback, waits and allocation in particle paths; measure before optimizing. Document buffer layout, ownership, coordinate/color spaces and frame lifecycle when adding passes.
- Runtime shader compilation requires actual device tests; Swift compilation is insufficient. Measure actual frame timing/device/resolution before performance claims.
- When persistence is authorized, use versioned documents, validation, explicit unknown-version handling and undo/redo. When expressions are authorized, use a restricted validated AST; never execute arbitrary user Swift/Metal.

## UI and validation
- Dark, canvas-first mathematical instrument; editorial/scientific minimalism. Use shared Design tokens and semantic fonts. No generic SaaS styling, decorative glow/gradients/glass or fake previews/data.
- Keyboard navigation, visible focus, accessible labels/contrast and Reduce Motion for interface transitions. Do not alter math for reduced motion.
- Use local visual-design-guardian for SwiftUI review, creative-rendering for Metal/visual edits, mathematical-correctness for solvers, performance-auditor for measurements.
- Run `TMPDIR=/private/tmp/ ./scripts/verify.sh check` for Swift Testing, release packaging and strict signature checks; `launch` adds app open. Do not run SwiftPM jobs concurrently in the shared scratch directory.
- With full Xcode run `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/verify.sh xcode` for the shared core/Metal/UI scheme. See `docs/DEVELOPMENT_WORKFLOW.md` for individual commands.
- For UI changes launch the real app and capture 1440×900 and 1280×800 point windows; also inspect Retina/large sizes where relevant. Store actual screenshots under `docs/evidence/<run>/screenshots/`. Check clipping, hierarchy, focus, invalid/disabled states, inspector snap/resize, occlusion and Reduce Motion. Rendering changes require a representative frame and measured timing.
- Report skipped GPU tests and unavailable Xcode/desktop checks explicitly. Never claim visual QA from a build/open exit status or animation acceptance from stills. No milestone completion without acceptance evidence.

## Git and PRs
- Inspect status, recent history, remotes and existing author identity before edits. This audited source snapshot has no `.git`; do not initialize a replacement or guess a remote. Resume Git operations in the genuine checkout.
- `main` is stable; use bounded `feature/<scope>` branches. Stage explicit files; make descriptive commits. Preserve author configuration and unrelated work.
- Publish only when authorized, using the authenticated account. PRs target `main` and include changes, executed tests, screenshots and known limitations. No AI co-author trailer unless repository policy requires it.
- Never push directly to main, merge without explicit approval, force-push, rewrite history, delete user files, expose credentials or create/publish a repository without explicit authorization.

## Graph navigation
- Read `graphify-out/GRAPH_REPORT.md`, traverse with `graphify explain`/`query`, then inspect source for exact behavior. Run `graphify update .` after code changes; distinguish local code freshness from semantic documentation coverage.
- Do not install global hooks/configuration or invoke paid semantic extraction merely to refresh the local graph.
