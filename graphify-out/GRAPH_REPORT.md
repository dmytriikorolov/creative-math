# Graph Report - creative-math-autonomous  (2026-11-13)

## Corpus Check
- 54 files · ~67,413 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 83 file(s) not represented in the graph (top: .log 78, (none) 1, .icns 1)
- WARNING: 83 of 194 files seen (43%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 955 nodes · 2314 edges · 47 communities (33 shown, 14 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 426 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `961bf61d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- LocalizedError
- LorenzConfiguration
- WormholeSession
- CameraMetalView
- Sendable
- SurfaceMotionSession
- EllisWormhole
- WormholeBeam
- LorenzError
- LorenzValidationOptions
- SurfaceSession
- TrailFade
- SurfaceRenderer
- PrimitiveRenderer
- MouseView
- SurfaceStyle
- LorenzSession
- SurfaceMesh
- WorkspaceUITests
- SurfaceViewRenderer
- SurfaceParameters
- build-app.sh
- test.sh
- validate-lorenz.sh
- Package.swift
- GeodesicSession
- OrbitCamera
- LorenzRenderer
- WorkspaceView
- CreativeMathApp.swift
- WorkspaceCore
- LorenzPreset
- SurfaceSession
- CameraAction
- .gallery
- verify.sh

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 41 edges
4. `SurfaceMotionSession` - 33 edges
5. `EllisWormhole` - 33 edges
6. `GeodesicSession` - 32 edges
7. `TorusGeodesicConfiguration` - 32 edges
8. `WorkspaceCore` - 31 edges
9. `WormholeComparison` - 30 edges
10. `WorkspaceView` - 29 edges

## Surprising Connections (you probably didn't know these)
- `restoredFunnelMatchesAcceptedSurfaceAndItsInducedMetric()` --calls--> `WormholeBeam`  [INFERRED]
  Tests/WorkspaceCoreTests/WormholeComparisonTests.swift → Sources/WorkspaceCore/WormholeComparison.swift
- `parallelStartsHaveSameHeadingAndUnitSurfaceSpeed()` --references--> `WormholeConfiguration`  [INFERRED]
  Tests/WorkspaceCoreTests/WormholeComparisonTests.swift → Sources/WorkspaceCore/EllisWormhole.swift
- `changingOneStartingPointChangesTheOutcomeWithoutChangingHeading()` --calls--> `WormholeSolver`  [INFERRED]
  Tests/WorkspaceCoreTests/WormholeComparisonTests.swift → Sources/WorkspaceCore/EllisWormhole.swift
- `fasterWormholePlaybackKeepsFixedStepsAndCatchUpBound()` --calls--> `WormholeSolver`  [INFERRED]
  Tests/WorkspaceCoreTests/WormholeComparisonTests.swift → Sources/WorkspaceCore/EllisWormhole.swift
- `roundedMeshWeldsOneEdgeAndKeepsFiniteSurfaceSamples()` --calls--> `WormholeConfiguration`  [INFERRED]
  Tests/WorkspaceCoreTests/WormholeComparisonTests.swift → Sources/WorkspaceCore/EllisWormhole.swift

## Import Cycles
- None detected.

## Communities (47 total, 14 thin omitted)

### Community 0 - "LocalizedError"
Cohesion: 0.20
Nodes (8): ValidationError, .errorDescription, gpuFailure, referenceMismatch, GeodesicError, .errorDescription, invalidConfiguration, unstableIntegration

### Community 1 - "LorenzConfiguration"
Cohesion: 0.06
Nodes (30): LorenzMetal, LorenzGPU, LorenzValidation, TimingSamples, FixedStepClock, LorenzConfiguration, .historyBytes, .isValid (+22 more)

### Community 2 - "WormholeSession"
Cohesion: 0.09
Nodes (20): WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance, .displayedParticle (+12 more)

### Community 4 - "Sendable"
Cohesion: 0.08
Nodes (27): GeodesicAppearance, .isValid, GeodesicPlayback, GeodesicTrail, TorusGeodesicConfiguration, .initialState, .isValid, TorusGeodesicSolver (+19 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.10
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.08
Nodes (29): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+21 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.06
Nodes (48): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+40 more)

### Community 8 - "LorenzError"
Cohesion: 0.22
Nodes (8): LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, LorenzRepresentation, line, ribbon

### Community 9 - "LorenzValidationOptions"
Cohesion: 0.31
Nodes (5): LorenzValidationOptions, OptionsError, .errorDescription, invalid, benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()

### Community 10 - "SurfaceSession"
Cohesion: 0.16
Nodes (11): SurfaceParameters, .formula, .isValid, SurfacePreset, .camera, .id, .parameters, .summary (+3 more)

### Community 11 - "TrailFade"
Cohesion: 0.08
Nodes (14): simd, GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries() (+6 more)

### Community 12 - "SurfaceRenderer"
Cohesion: 0.16
Nodes (3): GridVertex, SurfaceRenderer, SurfaceUniforms

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.13
Nodes (7): Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "SurfaceStyle"
Cohesion: 0.08
Nodes (24): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title (+16 more)

### Community 16 - "LorenzSession"
Cohesion: 0.18
Nodes (8): LorenzGalleryStudy, .body, .body, LorenzSession, .appearance, .configuration, .isPaused, .speed

### Community 17 - "SurfaceMesh"
Cohesion: 0.29
Nodes (5): SurfaceMeshKey, ellis, parametric, SurfaceMesh, meshBoundsSeamsAndParameterValidation()

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.21
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 23 - "SurfaceParameters"
Cohesion: 0.16
Nodes (12): CoordinateGrid, .isValid, .segments, .spacing, GridSegment, SurfaceSample, SurfaceVertex, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes() (+4 more)

### Community 24 - "build-app.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, build-app.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 25 - "test.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, test.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 26 - "validate-lorenz.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, validate-lorenz.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 31 - "GeodesicSession"
Cohesion: 0.09
Nodes (12): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+4 more)

### Community 32 - "OrbitCamera"
Cohesion: 0.08
Nodes (16): .body, DrawUniforms, LorenzTrails, CameraProjection, ParticleCameraTracking, RelaunchCameraTracking, .isTransitioning, OrbitCamera (+8 more)

### Community 33 - "LorenzRenderer"
Cohesion: 0.17
Nodes (3): Coordinator, LorenzRenderer, LorenzViewport

### Community 34 - "WorkspaceView"
Cohesion: 0.07
Nodes (36): CoreGraphics, GeodesicInspector, LorenzInspector, SurfaceInspector, GeodesicAxisLabels, .body, SurfaceAxisLabels, WorkspaceView (+28 more)

### Community 35 - "CreativeMathApp.swift"
Cohesion: 0.15
Nodes (11): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .surfaceSession, GeodesicSessionKey, LorenzCommands (+3 more)

### Community 36 - "WorkspaceCore"
Cohesion: 0.08
Nodes (13): AppKit, Foundation, Metal, MetalKit, Observation, word(), Design, SimulationUniforms (+5 more)

### Community 38 - "LorenzPreset"
Cohesion: 0.17
Nodes (11): LorenzAppearance, .isValid, LorenzPreset, .appearance, .camera, classic, filament, .id (+3 more)

### Community 39 - "SurfaceSession"
Cohesion: 0.17
Nodes (8): .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style, .surfaceDensity

### Community 41 - "CameraAction"
Cohesion: 0.50
Nodes (4): CameraAction, orbit, pan, zoom

### Community 49 - ".gallery"
Cohesion: 0.20
Nodes (7): GeodesicGalleryStudy, .body, SurfaceGalleryStudy, .body, .gallery, WormholeGalleryStudy, .body

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

## Knowledge Gaps
- **139 isolated node(s):** `.errorDescription`, `gpuFailure`, `referenceMismatch`, `.errorDescription`, `invalid` (+134 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 281 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `OrbitCamera`, `WorkspaceView`, `WorkspaceCore`, `SurfaceMotionSession`, `EllisWormhole`, `SurfaceSession`, `WormholeBeam`, `Sendable`, `TrailFade`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.errorDescription`, `gpuFailure`, `referenceMismatch` to the rest of the system?**
  _139 weakly-connected nodes found - possible missing edges._
- **Should `LorenzConfiguration` be split into smaller, more focused modules?**
  _Cohesion score 0.05827505827505827 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `OrbitCamera` to `LorenzRenderer`, `WorkspaceView`, `WormholeSession`, `LorenzConfiguration`, `SurfaceMotionSession`, `EllisWormhole`, `SurfaceSession`, `LorenzPreset`, `Sendable`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `GeodesicSession`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.08536585365853659 - nodes in this community are weakly interconnected._