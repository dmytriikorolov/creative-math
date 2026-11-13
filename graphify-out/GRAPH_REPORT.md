# Graph Report - creative-math-ux01  (2026-11-13)

## Corpus Check
- 58 files · ~71,107 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 92 file(s) not represented in the graph (top: .log 87, (none) 1, .icns 1)
- WARNING: 92 of 211 files seen (44%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 1061 nodes · 2549 edges · 56 communities (38 shown, 18 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 444 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3a09401a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .run
- LorenzParameters
- WormholeSession
- PlanarDomain
- TorusGeodesicConfiguration
- SurfaceMotionSession
- EllisWormhole
- Sendable
- View
- FixedStepClock
- SurfaceSession
- TrailFade
- SurfaceRenderer
- PrimitiveRenderer
- MouseView
- LibraryCategory
- LorenzSession
- FocusedValues
- LorenzValidationOptions
- WorkspaceUITests
- SurfaceViewRenderer
- LorenzGPU
- ObjectivePreset
- build-app.sh
- test.sh
- validate-lorenz.sh
- Package.swift
- simd
- GeodesicSession
- WorkspaceCore
- ObjectiveSample
- PanelPlacementTests.swift
- LocalizedError
- WormholeLaunch
- LorenzGPU.swift
- LorenzPreset
- WorkspaceScene
- String
- OptimizationStatus
- OptimizationMethod
- Edges
- WorkspaceView
- verify.sh

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 40 edges
4. `WorkspaceCore` - 33 edges
5. `SurfaceMotionSession` - 33 edges
6. `EllisWormhole` - 33 edges
7. `WorkspaceView` - 32 edges
8. `GeodesicSession` - 32 edges
9. `TorusGeodesicConfiguration` - 32 edges
10. `WormholeConfiguration` - 29 edges

## Surprising Connections (you probably didn't know these)
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `packedTransportStaysStableAlongLorenzTrajectory()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/TrailGeometryTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzReference`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `geodesicOverlayPreservesSurfaceDepthAndFrozenHistory()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/GeodesicRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift
- `ellisRendererModesReuseGeometryAndDrawActualTrajectories()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/WormholeRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift

## Import Cycles
- None detected.

## Communities (56 total, 18 thin omitted)

### Community 1 - "LorenzParameters"
Cohesion: 0.18
Nodes (12): LorenzMath, LorenzParameters, .isValid, LorenzReference, equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria(), parameterValidationAndStableReference() (+4 more)

### Community 2 - "WormholeSession"
Cohesion: 0.06
Nodes (31): WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance, .displayedParticle (+23 more)

### Community 3 - "PlanarDomain"
Cohesion: 0.10
Nodes (13): Design, OptimizationInspector, .body, OptimizationSession, OptimizationWorkspace, .body, PlanarPlot, LevelSegment (+5 more)

### Community 4 - "TorusGeodesicConfiguration"
Cohesion: 0.08
Nodes (28): .segments, GeodesicAppearance, .isValid, GeodesicPlayback, GeodesicTrail, TorusGeodesicConfiguration, .initialState, .isValid (+20 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.10
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.08
Nodes (29): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+21 more)

### Community 7 - "Sendable"
Cohesion: 0.06
Nodes (47): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+39 more)

### Community 8 - "View"
Cohesion: 0.11
Nodes (16): GeodesicGalleryStudy, .body, GeodesicInspector, LorenzGalleryStudy, .body, LorenzInspector, SurfaceGalleryStudy, SurfaceInspector (+8 more)

### Community 9 - "FixedStepClock"
Cohesion: 0.39
Nodes (4): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate()

### Community 10 - "SurfaceSession"
Cohesion: 0.13
Nodes (9): .body, .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style (+1 more)

### Community 11 - "TrailFade"
Cohesion: 0.09
Nodes (13): GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint() (+5 more)

### Community 12 - "SurfaceRenderer"
Cohesion: 0.05
Nodes (35): GridVertex, SurfaceMeshKey, ellis, parametric, SurfaceRenderer, SurfaceUniforms, CoordinateGrid, .isValid (+27 more)

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.12
Nodes (8): MetalKit, Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "LibraryCategory"
Cohesion: 0.21
Nodes (8): LibraryCategory, all, dynamics, geometry, .id, optimization, LibraryExperiment, .experimentLibrary

### Community 16 - "LorenzSession"
Cohesion: 0.06
Nodes (18): LorenzMetal, .body, NumericControl, .body, LorenzSession, .appearance, .configuration, .isPaused (+10 more)

### Community 17 - "FocusedValues"
Cohesion: 0.14
Nodes (13): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .optimizationSession, .surfaceSession, GeodesicSessionKey (+5 more)

### Community 18 - "LorenzValidationOptions"
Cohesion: 0.31
Nodes (5): LorenzValidationOptions, OptionsError, .errorDescription, invalid, benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.21
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 21 - "LorenzGPU"
Cohesion: 0.16
Nodes (10): LorenzGPU, LorenzConfiguration, .historyBytes, .isValid, gpuMatchesCPUReferenceAndResets(), gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused(), gpuRingContentsAndPresetTransitions() (+2 more)

### Community 23 - "ObjectivePreset"
Cohesion: 0.14
Nodes (13): Objective2D, ObjectivePreset, .domain, doubleWell, .formula, .id, illConditioned, quadratic (+5 more)

### Community 24 - "build-app.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, build-app.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 25 - "test.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, test.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 26 - "validate-lorenz.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, validate-lorenz.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 30 - "simd"
Cohesion: 0.23
Nodes (10): simd, OptimizationRun, .canStep, .current, OptimizationSettings, .isValid, objectiveDerivativesMatchIndependentCentralDifferences(), optimizationMethodsConvergeOnQuadraticAndRepeatExactly() (+2 more)

### Community 31 - "GeodesicSession"
Cohesion: 0.12
Nodes (10): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+2 more)

### Community 32 - "WorkspaceCore"
Cohesion: 0.09
Nodes (12): AppKit, Foundation, Metal, Observation, word(), DrawUniforms, LorenzTrails, SurfaceMetal (+4 more)

### Community 33 - "ObjectiveSample"
Cohesion: 0.36
Nodes (3): ObjectiveSample, .minimumCurvature, OptimizationRecord

### Community 34 - "PanelPlacementTests.swift"
Cohesion: 0.15
Nodes (17): CoreGraphics, PanelPlacement, PanelPreferences, clampingFitsSmallerWorkspaceAndIsIdempotent(), defaultSizeRestorationKeepsPositionWhenPossible(), dragClampsAtEveryBoundary(), dragUsesInitialFrameAndTotalTranslation(), invalidFrameRecoversToFiniteDefault() (+9 more)

### Community 35 - "LocalizedError"
Cohesion: 0.20
Nodes (8): ValidationError, .errorDescription, gpuFailure, referenceMismatch, GeodesicError, .errorDescription, invalidConfiguration, unstableIntegration

### Community 36 - "WormholeLaunch"
Cohesion: 0.22
Nodes (8): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title

### Community 38 - "LorenzPreset"
Cohesion: 0.09
Nodes (20): LorenzAppearance, .isValid, LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, LorenzPreset (+12 more)

### Community 39 - "WorkspaceScene"
Cohesion: 0.20
Nodes (9): WorkspaceScene, blank, lorenz, optimization, surface, .title, torusGeodesics, triangle (+1 more)

### Community 40 - "String"
Cohesion: 0.17
Nodes (11): WormholePresentation, .id, surface, .title, trajectories, wireframe, SurfaceError, .errorDescription (+3 more)

### Community 41 - "OptimizationStatus"
Cohesion: 0.22
Nodes (9): OptimizationStatus, converged, iterationLimit, lineSearchFailed, nonminimum, numericalLimit, ready, running (+1 more)

### Community 49 - "OptimizationMethod"
Cohesion: 0.29
Nodes (6): .isFinite, OptimizationMethod, gradient, .id, momentum, newton

### Community 51 - "WorkspaceView"
Cohesion: 0.35
Nodes (4): WorkspaceView, .activeMotion, .body, .studyDetails

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

## Knowledge Gaps
- **170 isolated node(s):** `.optimizationSession`, `.geodesicSession`, `.surfaceSession`, `.lorenzSession`, `.body` (+165 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 319 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `WorkspaceCore`, `TorusGeodesicConfiguration`, `SurfaceMotionSession`, `EllisWormhole`, `Sendable`, `SurfaceSession`, `TrailFade`, `WorkspaceView`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.optimizationSession`, `.geodesicSession`, `.surfaceSession` to the rest of the system?**
  _170 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.056140350877192984 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `WormholeSession` to `WorkspaceCore`, `LorenzParameters`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `View`, `Sendable`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `LorenzSession`, `GeodesicSession`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `PlanarDomain` be split into smaller, more focused modules?**
  _Cohesion score 0.10121457489878542 - nodes in this community are weakly interconnected._