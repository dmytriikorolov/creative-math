# Graph Report - creative-math-pr-finish  (2026-11-16)

## Corpus Check
- 61 files · ~74,748 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 111 file(s) not represented in the graph (top: .log 106, (none) 1, .icns 1)
- WARNING: 111 of 246 files seen (45%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 1140 nodes · 2734 edges · 64 communities (42 shown, 22 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 478 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `0f00e5d4`
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
- .draw
- PrimitiveRenderer
- MouseView
- String
- LorenzSession
- VectorFieldSession
- Sendable
- WorkspaceUITests
- SurfaceViewRenderer
- LorenzGPU
- SurfaceParameters
- build-app.sh
- test.sh
- validate-lorenz.sh
- Package.swift
- CoordinateGrid
- GeodesicSession
- .encode
- simd
- WorkspaceView
- SurfacePreset
- ObjectivePreset
- WorkspaceCore
- LorenzPreset
- OptimizationStatus
- SurfaceRenderer
- OptimizationMethod
- .gallery
- Optimization.swift
- VectorFieldPreset
- LorenzTests.swift
- verify.sh
- VectorTrajectoryStatus
- SurfaceMesh

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 41 edges
4. `WorkspaceCore` - 35 edges
5. `WorkspaceView` - 35 edges
6. `SurfaceMotionSession` - 33 edges
7. `EllisWormhole` - 33 edges
8. `GeodesicSession` - 32 edges
9. `TorusGeodesicConfiguration` - 32 edges
10. `WormholeComparison` - 30 edges

## Surprising Connections (you probably didn't know these)
- `validationRejectsEveryNonFiniteModelComponentAndCountBoundary()` --calls--> `LorenzConfiguration`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `coordinateGridIsBoundedAndContainsAxesAndTicks()` --calls--> `CoordinateGrid`  [INFERRED]
  Tests/WorkspaceCoreTests/SurfaceTests.swift → Sources/WorkspaceCore/ParametricSurface.swift
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `equilibriumIsInvariantAndZAxisMatchesAnalyticDecay()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `lorenzDerivativeAndEquilibria()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/Lorenz.swift

## Import Cycles
- None detected.

## Communities (64 total, 22 thin omitted)

### Community 0 - ".run"
Cohesion: 0.17
Nodes (6): LorenzValidation, TimingSamples, ValidationError, .errorDescription, gpuFailure, referenceMismatch

### Community 1 - "LorenzParameters"
Cohesion: 0.23
Nodes (8): LorenzMath, LorenzParameters, .isValid, LorenzReference, parameterValidationAndStableReference(), seededResetAndBatchingAreRepeatable(), stableDynamicsConvergeWithoutRecoveryOrForcedMotion(), supportedParameterCornersRemainFinite()

### Community 2 - "WormholeSession"
Cohesion: 0.06
Nodes (32): .body, WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance (+24 more)

### Community 3 - "PlanarDomain"
Cohesion: 0.09
Nodes (15): Design, NumericControl, .body, OptimizationInspector, .body, OptimizationSession, .body, PlanarPlot (+7 more)

### Community 4 - "Sendable"
Cohesion: 0.08
Nodes (27): GeodesicAppearance, .isValid, GeodesicPlayback, GeodesicTrail, TorusGeodesicConfiguration, .initialState, .isValid, TorusGeodesicSolver (+19 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.07
Nodes (10): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch (+2 more)

### Community 6 - "EllisWormhole"
Cohesion: 0.08
Nodes (30): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+22 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.06
Nodes (47): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+39 more)

### Community 8 - "SwiftUI"
Cohesion: 0.20
Nodes (7): GeodesicGalleryStudy, .body, SurfaceGalleryStudy, .body, .gallery, WormholeGalleryStudy, .body

### Community 9 - "FixedStepClock"
Cohesion: 0.29
Nodes (4): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate()

### Community 10 - "SurfaceSession"
Cohesion: 0.13
Nodes (8): .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style, .surfaceDensity

### Community 11 - "TrailFade"
Cohesion: 0.18
Nodes (11): RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint(), fadeZeroDurationInvalidInputsAndHistoryLimits(), packedRibbonFramesAreFiniteAndKeepPrecision() (+3 more)

### Community 12 - ".draw"
Cohesion: 0.22
Nodes (5): GridVertex, SurfaceMeshKey, ellis, parametric, SurfaceUniforms

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.13
Nodes (7): Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.16
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "String"
Cohesion: 0.07
Nodes (28): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title (+20 more)

### Community 16 - "LorenzSession"
Cohesion: 0.06
Nodes (17): LorenzGalleryStudy, .body, .body, LorenzSession, .appearance, .configuration, .isPaused, .speed (+9 more)

### Community 17 - "VectorFieldSession"
Cohesion: 0.08
Nodes (22): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .planarSession, .surfaceSession, GeodesicSessionKey (+14 more)

### Community 18 - "Sendable"
Cohesion: 0.16
Nodes (15): PlanarVectorField, .domain, .isValid, VectorField2D, .isValid, VectorIntegrationSettings, .isValid, VectorTrajectory (+7 more)

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.19
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 21 - "LorenzGPU"
Cohesion: 0.17
Nodes (10): LorenzGPU, LorenzConfiguration, .historyBytes, .isValid, gpuMatchesCPUReferenceAndResets(), gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused(), gpuRingContentsAndPresetTransitions() (+2 more)

### Community 23 - "SurfaceParameters"
Cohesion: 0.31
Nodes (5): SurfaceSample, analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents(), coordinateGridIsBoundedAndContainsAxesAndTicks(), torusSamplesSatisfyImplicitSurfaceAndPeriodicSeams(), wormholeHasOpenThroatFixedRimAndContinuousFlatLimit()

### Community 24 - "build-app.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, build-app.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 25 - "test.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, test.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 26 - "validate-lorenz.sh"
Cohesion: 0.50
Nodes (3): CLANG_MODULE_CACHE_PATH, validate-lorenz.sh script, SWIFTPM_MODULECACHE_OVERRIDE

### Community 30 - "CoordinateGrid"
Cohesion: 0.25
Nodes (7): CoordinateGrid, .isValid, .segments, .spacing, GridSegment, SurfaceVertex, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes()

### Community 31 - "GeodesicSession"
Cohesion: 0.12
Nodes (10): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+2 more)

### Community 32 - ".encode"
Cohesion: 0.15
Nodes (4): DrawUniforms, LorenzTrails, cameraProjectionPreservesAxesDepthAndAspect(), surfaceCameraProjectionMatchesExistingLorenzConvention()

### Community 33 - "simd"
Cohesion: 0.16
Nodes (14): simd, Objective2D, ObjectiveSample, .minimumCurvature, OptimizationRecord, OptimizationRun, .canStep, .current (+6 more)

### Community 34 - "WorkspaceView"
Cohesion: 0.05
Nodes (47): CoreGraphics, GeodesicInspector, LorenzInspector, OptimizationWorkspace, SurfaceInspector, GeodesicAxisLabels, .body, SurfaceAxisLabels (+39 more)

### Community 35 - "SurfacePreset"
Cohesion: 0.16
Nodes (11): SurfaceParameters, .formula, .isValid, SurfacePreset, .camera, .id, .parameters, .summary (+3 more)

### Community 36 - "ObjectivePreset"
Cohesion: 0.20
Nodes (10): ObjectivePreset, .domain, doubleWell, .formula, .id, illConditioned, quadratic, rosenbrock (+2 more)

### Community 37 - "WorkspaceCore"
Cohesion: 0.08
Nodes (13): AppKit, Foundation, LorenzMetal, Metal, MetalKit, Observation, word(), SimulationUniforms (+5 more)

### Community 38 - "LorenzPreset"
Cohesion: 0.12
Nodes (15): LorenzAppearance, .isValid, LorenzPreset, .appearance, .camera, classic, .configuration, filament (+7 more)

### Community 39 - "OptimizationStatus"
Cohesion: 0.22
Nodes (9): OptimizationStatus, converged, iterationLimit, lineSearchFailed, nonminimum, numericalLimit, ready, running (+1 more)

### Community 41 - "OptimizationMethod"
Cohesion: 0.33
Nodes (6): .isFinite, OptimizationMethod, gradient, .id, momentum, newton

### Community 49 - ".gallery"
Cohesion: 0.12
Nodes (14): LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, LorenzValidationOptions, OptionsError, .errorDescription (+6 more)

### Community 50 - "Optimization.swift"
Cohesion: 0.40
Nodes (4): OptimizationError, invalidConfiguration, VectorIntegrationError, invalidConfiguration

### Community 51 - "VectorFieldPreset"
Cohesion: 0.22
Nodes (8): VectorFieldPreset, .defaultParameter, .formula, .id, oscillator, saddle, spiral, vanDerPol

### Community 52 - "LorenzTests.swift"
Cohesion: 0.31
Nodes (6): equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria(), rk4MatchesIndependentDOP853AndConverges(), validationRejectsEveryNonFiniteModelComponentAndCountBoundary(), oscillatorIntegratorsShowExpectedConvergenceOrder()

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

### Community 56 - "VectorTrajectoryStatus"
Cohesion: 0.33
Nodes (6): VectorTrajectoryStatus, equilibrium, numericalLimit, ready, running, stepLimit

## Knowledge Gaps
- **195 isolated node(s):** `.planarSession`, `.geodesicSession`, `.surfaceSession`, `.lorenzSession`, `.body` (+190 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 351 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `WorkspaceView`, `Sendable`, `SurfaceMotionSession`, `WorkspaceCore`, `WormholeBeam`, `EllisWormhole`, `SurfaceSession`, `TrailFade`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.planarSession`, `.geodesicSession`, `.surfaceSession` to the rest of the system?**
  _195 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.05578947368421053 - nodes in this community are weakly interconnected._
- **Why does `WorkspaceView` connect `WorkspaceView` to `WormholeSession`, `SurfaceMotionSession`, `WorkspaceCore`, `SwiftUI`, `SurfaceSession`, `PrimitiveRenderer`, `LorenzSession`, `VectorFieldSession`, `GeodesicSession`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `PlanarDomain` be split into smaller, more focused modules?**
  _Cohesion score 0.08502415458937199 - nodes in this community are weakly interconnected._