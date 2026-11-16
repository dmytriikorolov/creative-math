# Graph Report - creative-math-pr-finish  (2026-11-15)

## Corpus Check
- 58 files · ~72,195 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 102 file(s) not represented in the graph (top: .log 97, (none) 1, .icns 1)
- WARNING: 102 of 230 files seen (44%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 1062 nodes · 2555 edges · 60 communities (40 shown, 20 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 449 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a06dfdd7`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .run
- LorenzParameters
- WormholeSession
- PlanarDomain
- Sendable
- SurfaceMotionSession
- EllisWormhole
- WormholeBeam
- SwiftUI
- FixedStepClock
- SurfaceSession
- TrailFade
- SurfaceRenderer
- PrimitiveRenderer
- MouseView
- String
- LorenzSession
- CreativeMathApp.swift
- TorusMetric
- WorkspaceUITests
- SurfaceViewRenderer
- LorenzGPU
- SurfaceParameters
- build-app.sh
- test.sh
- validate-lorenz.sh
- Package.swift
- Sendable
- GeodesicSession
- .encode
- ObjectiveSample
- WorkspaceView
- OptimizationRun
- ObjectivePreset
- TrajectorySnapshot
- LorenzPreset
- OptimizationStatus
- NumericControl
- OptimizationMethod
- .gallery
- Optimization.swift
- FocusedValues
- SurfaceStyle
- verify.sh
- TrajectorySnapshot
- PanelMouseRegion.swift

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 41 edges
4. `WorkspaceCore` - 33 edges
5. `SurfaceMotionSession` - 33 edges
6. `EllisWormhole` - 33 edges
7. `WorkspaceView` - 32 edges
8. `GeodesicSession` - 32 edges
9. `TorusGeodesicConfiguration` - 32 edges
10. `WormholeComparison` - 30 edges

## Surprising Connections (you probably didn't know these)
- `coordinateGridIsBoundedAndContainsAxesAndTicks()` --calls--> `CoordinateGrid`  [INFERRED]
  Tests/WorkspaceCoreTests/SurfaceTests.swift → Sources/WorkspaceCore/ParametricSurface.swift
- `packedTransportStaysStableAlongLorenzTrajectory()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/TrailGeometryTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `geodesicOverlayPreservesSurfaceDepthAndFrozenHistory()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/GeodesicRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift
- `ellisRendererModesReuseGeometryAndDrawActualTrajectories()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/WormholeRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift
- `geodesicOverlayPreservesSurfaceDepthAndFrozenHistory()` --calls--> `TrailFade`  [INFERRED]
  Tests/LorenzMetalTests/GeodesicRenderingTests.swift → Sources/WorkspaceCore/TrailGeometry.swift

## Import Cycles
- None detected.

## Communities (60 total, 20 thin omitted)

### Community 1 - "LorenzParameters"
Cohesion: 0.19
Nodes (13): LorenzMath, LorenzParameters, .isValid, LorenzReference, gpuMatchesCPUReferenceAndResets(), equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria() (+5 more)

### Community 2 - "WormholeSession"
Cohesion: 0.09
Nodes (20): WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance, .displayedParticle (+12 more)

### Community 3 - "PlanarDomain"
Cohesion: 0.11
Nodes (12): OptimizationInspector, .body, OptimizationSession, OptimizationWorkspace, .body, PlanarPlot, LevelSegment, ObjectiveGrid (+4 more)

### Community 4 - "Sendable"
Cohesion: 0.08
Nodes (27): .segments, GeodesicAppearance, .isValid, GeodesicPlayback, GeodesicTrail, TorusGeodesicConfiguration, .isValid, TorusGeodesicSolver (+19 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.10
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.07
Nodes (37): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+29 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.06
Nodes (49): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+41 more)

### Community 8 - "SwiftUI"
Cohesion: 0.14
Nodes (8): Design, GeodesicGalleryStudy, .body, SurfaceGalleryStudy, .gallery, WormholeGalleryStudy, .body, SwiftUI

### Community 9 - "FixedStepClock"
Cohesion: 0.33
Nodes (4): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate()

### Community 10 - "SurfaceSession"
Cohesion: 0.10
Nodes (16): .body, .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style (+8 more)

### Community 11 - "TrailFade"
Cohesion: 0.09
Nodes (13): GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint() (+5 more)

### Community 12 - "SurfaceRenderer"
Cohesion: 0.13
Nodes (7): GridVertex, SurfaceRenderer, SurfaceUniforms, CoordinateGrid, .isValid, .spacing, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes()

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.12
Nodes (8): MetalKit, Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "String"
Cohesion: 0.17
Nodes (11): WormholePresentation, .id, surface, .title, trajectories, wireframe, SurfaceError, .errorDescription (+3 more)

### Community 16 - "LorenzSession"
Cohesion: 0.06
Nodes (17): LorenzGalleryStudy, .body, .body, LorenzSession, .appearance, .configuration, .isPaused, .speed (+9 more)

### Community 17 - "CreativeMathApp.swift"
Cohesion: 0.21
Nodes (8): CreativeMathApp, .body, GeodesicSessionKey, LorenzCommands, .body, LorenzSessionKey, OptimizationSessionKey, SurfaceSessionKey

### Community 18 - "TorusMetric"
Cohesion: 0.31
Nodes (5): LorenzValidationOptions, OptionsError, .errorDescription, invalid, benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.17
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 21 - "LorenzGPU"
Cohesion: 0.14
Nodes (9): LorenzGPU, LorenzConfiguration, .historyBytes, .isValid, gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRingContentsAndPresetTransitions(), gpuStableDynamicsSettleWithoutRestarting(), validationRejectsEveryNonFiniteModelComponentAndCountBoundary() (+1 more)

### Community 23 - "SurfaceParameters"
Cohesion: 0.18
Nodes (9): SurfaceParameters, .formula, .isValid, .parameters, SurfaceSample, analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents(), coordinateGridIsBoundedAndContainsAxesAndTicks(), torusSamplesSatisfyImplicitSurfaceAndPeriodicSeams() (+1 more)

### Community 24 - "build-app.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, build-app.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 25 - "test.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, test.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 26 - "validate-lorenz.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, validate-lorenz.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 30 - "Sendable"
Cohesion: 0.21
Nodes (7): SurfaceMeshKey, ellis, parametric, GridSegment, SurfaceMesh, SurfaceVertex, meshBoundsSeamsAndParameterValidation()

### Community 31 - "GeodesicSession"
Cohesion: 0.12
Nodes (10): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+2 more)

### Community 32 - ".encode"
Cohesion: 0.08
Nodes (16): DrawUniforms, LorenzTrails, CameraProjection, ParticleCameraTracking, RelaunchCameraTracking, .isTransitioning, OrbitCamera, cameraProjectionPreservesAxesDepthAndAspect() (+8 more)

### Community 33 - "ObjectiveSample"
Cohesion: 0.36
Nodes (3): ObjectiveSample, .minimumCurvature, OptimizationRecord

### Community 34 - "WorkspaceView"
Cohesion: 0.05
Nodes (45): CoreGraphics, GeodesicInspector, LorenzInspector, SurfaceInspector, GeodesicAxisLabels, .body, SurfaceAxisLabels, .body (+37 more)

### Community 35 - "OptimizationRun"
Cohesion: 0.26
Nodes (9): OptimizationRun, .canStep, .current, OptimizationSettings, .isValid, objectiveDerivativesMatchIndependentCentralDifferences(), optimizationMethodsConvergeOnQuadraticAndRepeatExactly(), safeguardedNewtonHandlesNonconvexAndIllConditionedObjectives() (+1 more)

### Community 36 - "ObjectivePreset"
Cohesion: 0.20
Nodes (10): ObjectivePreset, .domain, doubleWell, .formula, .id, illConditioned, quadratic, rosenbrock (+2 more)

### Community 37 - "TrajectorySnapshot"
Cohesion: 0.20
Nodes (8): Foundation, LorenzMetal, Metal, Observation, simd, SurfaceMetal, Testing, WorkspaceCore

### Community 38 - "LorenzPreset"
Cohesion: 0.12
Nodes (15): LorenzAppearance, .isValid, LorenzPreset, .appearance, .camera, classic, .configuration, filament (+7 more)

### Community 39 - "OptimizationStatus"
Cohesion: 0.22
Nodes (9): OptimizationStatus, converged, iterationLimit, lineSearchFailed, nonminimum, numericalLimit, ready, running (+1 more)

### Community 41 - "OptimizationMethod"
Cohesion: 0.29
Nodes (6): .isFinite, OptimizationMethod, gradient, .id, momentum, newton

### Community 49 - ".gallery"
Cohesion: 0.13
Nodes (13): ValidationError, .errorDescription, gpuFailure, referenceMismatch, LorenzError, .errorDescription, invalidConfiguration, metalUnavailable (+5 more)

### Community 50 - "Optimization.swift"
Cohesion: 0.40
Nodes (3): Objective2D, OptimizationError, invalidConfiguration

### Community 51 - "FocusedValues"
Cohesion: 0.40
Nodes (5): FocusedValues, .geodesicSession, .lorenzSession, .optimizationSession, .surfaceSession

### Community 52 - "SurfaceStyle"
Cohesion: 0.40
Nodes (5): SurfaceStyle, .id, shaded, .title, wireframe

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

## Knowledge Gaps
- **170 isolated node(s):** `.optimizationSession`, `.geodesicSession`, `.surfaceSession`, `.lorenzSession`, `.body` (+165 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 319 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `OrbitCamera` connect `.encode` to `LorenzParameters`, `WorkspaceView`, `Sendable`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `LorenzSession`, `GeodesicSession`?**
  _High betweenness centrality (0.101) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.optimizationSession`, `.geodesicSession`, `.surfaceSession` to the rest of the system?**
  _170 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.08846153846153847 - nodes in this community are weakly interconnected._
- **Why does `WorkspaceCore` connect `TrajectorySnapshot` to `LorenzParameters`, `WorkspaceView`, `PlanarDomain`, `Sendable`, `SurfaceMotionSession`, `OptimizationRun`, `WormholeBeam`, `SwiftUI`, `EllisWormhole`, `TrailFade`, `PrimitiveRenderer`, `LorenzSession`, `SurfaceParameters`, `PanelMouseRegion.swift`?**
  _High betweenness centrality (0.088) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `PlanarDomain` be split into smaller, more focused modules?**
  _Cohesion score 0.10960960960960961 - nodes in this community are weakly interconnected._