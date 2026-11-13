# Graph Report - creative-math-ux01  (2026-11-13)

## Corpus Check
- 61 files · ~73,924 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 98 file(s) not represented in the graph (top: .log 93, (none) 1, .icns 1)
- WARNING: 98 of 223 files seen (44%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 1139 nodes · 2728 edges · 71 communities (47 shown, 24 thin omitted)
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 473 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3740f0f9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .run
- LorenzParameters
- WormholeSession
- PlanarDomain
- TorusMetric
- SurfaceMotionSession
- EllisWormhole
- Sendable
- VectorFieldSession
- FixedStepClock
- SurfaceSession
- TrailFade
- .draw
- PrimitiveRenderer
- MouseView
- TorusGeodesicConfiguration
- LorenzSession
- SurfaceParameters
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
- OrbitCamera
- ObjectiveSample
- WorkspaceView
- LocalizedError
- WormholeLaunch
- WorkspaceCore
- LorenzPreset
- GeodesicPlayback
- String
- OptimizationStatus
- OptimizationMethod
- LorenzRenderer
- PlanarVectorField
- verify.sh
- CameraMetalView
- VectorTrajectory
- SurfaceRenderer
- GeodesicAppearance
- CoordinateGrid
- CameraAction
- VectorFieldPreset
- VectorTrajectoryStatus
- OptimizationError
- .initialPoint

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 40 edges
4. `WorkspaceCore` - 35 edges
5. `WorkspaceView` - 35 edges
6. `SurfaceMotionSession` - 33 edges
7. `EllisWormhole` - 33 edges
8. `GeodesicSession` - 32 edges
9. `TorusGeodesicConfiguration` - 32 edges
10. `WormholeConfiguration` - 29 edges

## Surprising Connections (you probably didn't know these)
- `validationRejectsEveryNonFiniteModelComponentAndCountBoundary()` --calls--> `LorenzConfiguration`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `coordinateGridIsBoundedAndContainsAxesAndTicks()` --calls--> `CoordinateGrid`  [INFERRED]
  Tests/WorkspaceCoreTests/SurfaceTests.swift → Sources/WorkspaceCore/ParametricSurface.swift
- `seededResetAndBatchingAreRepeatable()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `packedTransportStaysStableAlongLorenzTrajectory()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/TrailGeometryTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzConfiguration`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift

## Import Cycles
- None detected.

## Communities (71 total, 24 thin omitted)

### Community 0 - ".run"
Cohesion: 0.17
Nodes (6): LorenzValidation, TimingSamples, ValidationError, .errorDescription, gpuFailure, referenceMismatch

### Community 1 - "LorenzParameters"
Cohesion: 0.18
Nodes (13): LorenzMath, LorenzParameters, .isValid, LorenzReference, gpuMatchesCPUReferenceAndResets(), equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria() (+5 more)

### Community 2 - "WormholeSession"
Cohesion: 0.09
Nodes (20): WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance, .displayedParticle (+12 more)

### Community 3 - "PlanarDomain"
Cohesion: 0.09
Nodes (15): Design, NumericControl, .body, OptimizationInspector, .body, OptimizationSession, .body, PlanarPlot (+7 more)

### Community 4 - "TorusMetric"
Cohesion: 0.23
Nodes (6): .initialState, .position, .relativeSpeedDrift, TorusMetric, .isValid, torusMetricAndAccelerationMatchGeometry()

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.11
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.08
Nodes (30): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+22 more)

### Community 7 - "Sendable"
Cohesion: 0.06
Nodes (48): simd, .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary (+40 more)

### Community 8 - "VectorFieldSession"
Cohesion: 0.16
Nodes (9): OptimizationSession, .canStep, PlanarTransportSession, VectorDirectionSample, VectorFieldInspector, .body, VectorFieldSession, .canStep (+1 more)

### Community 9 - "FixedStepClock"
Cohesion: 0.36
Nodes (5): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate(), variableFixedStepClockKeepsCadencePauseAndCatchUpBound()

### Community 10 - "SurfaceSession"
Cohesion: 0.10
Nodes (17): SurfaceGalleryStudy, .body, .body, SurfaceSession, .camera, .grid, .parameters, .preset (+9 more)

### Community 11 - "TrailFade"
Cohesion: 0.09
Nodes (13): GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint() (+5 more)

### Community 12 - ".draw"
Cohesion: 0.21
Nodes (5): GridVertex, SurfaceMeshKey, ellis, parametric, SurfaceUniforms

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.13
Nodes (7): Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "TorusGeodesicConfiguration"
Cohesion: 0.22
Nodes (14): TorusGeodesicConfiguration, .isValid, TorusGeodesicSolver, equatorialGeodesicsTraceActualCirclesOverMultipleLaps(), extendedGeodesicsStayFiniteOnSurfaceWithMeasuredDrift(), geodesicClockIsIndependentOfDisplayRefresh(), integrationRestartBatchingAndRingHistoryAreDeterministic(), invalidGeodesicInputsAreRejected() (+6 more)

### Community 16 - "LorenzSession"
Cohesion: 0.07
Nodes (21): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .planarSession, .surfaceSession, GeodesicSessionKey (+13 more)

### Community 17 - "SurfaceParameters"
Cohesion: 0.18
Nodes (10): SurfaceParameters, .formula, .isValid, .parameters, SurfaceSample, analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents(), coordinateGridIsBoundedAndContainsAxesAndTicks(), meshBoundsSeamsAndParameterValidation() (+2 more)

### Community 18 - "LorenzValidationOptions"
Cohesion: 0.31
Nodes (5): LorenzValidationOptions, OptionsError, .errorDescription, invalid, benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.12
Nodes (7): GeodesicGalleryStudy, .body, Coordinator, SurfaceViewport, SurfaceViewRenderer, WormholeGalleryStudy, .body

### Community 21 - "LorenzGPU"
Cohesion: 0.18
Nodes (6): LorenzGPU, gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused(), gpuRingContentsAndPresetTransitions(), gpuStableDynamicsSettleWithoutRestarting(), preferencesMigrateExistingPositionAndDefaultMissingDimensions()

### Community 23 - "ObjectivePreset"
Cohesion: 0.20
Nodes (10): ObjectivePreset, .domain, doubleWell, .formula, .id, illConditioned, quadratic, rosenbrock (+2 more)

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
Cohesion: 0.19
Nodes (11): Objective2D, OptimizationRecord, OptimizationRun, .canStep, .current, OptimizationSettings, .isValid, objectiveDerivativesMatchIndependentCentralDifferences() (+3 more)

### Community 31 - "GeodesicSession"
Cohesion: 0.11
Nodes (11): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+3 more)

### Community 32 - "OrbitCamera"
Cohesion: 0.08
Nodes (16): .body, DrawUniforms, LorenzTrails, CameraProjection, ParticleCameraTracking, RelaunchCameraTracking, .isTransitioning, OrbitCamera (+8 more)

### Community 34 - "WorkspaceView"
Cohesion: 0.05
Nodes (47): CoreGraphics, GeodesicInspector, LorenzInspector, OptimizationWorkspace, SurfaceInspector, GeodesicAxisLabels, .body, SurfaceAxisLabels (+39 more)

### Community 35 - "LocalizedError"
Cohesion: 0.18
Nodes (9): LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, GeodesicError, .errorDescription, invalidConfiguration (+1 more)

### Community 36 - "WormholeLaunch"
Cohesion: 0.22
Nodes (8): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title

### Community 37 - "WorkspaceCore"
Cohesion: 0.08
Nodes (13): AppKit, Foundation, LorenzMetal, Metal, MetalKit, Observation, word(), SimulationUniforms (+5 more)

### Community 38 - "LorenzPreset"
Cohesion: 0.11
Nodes (18): LorenzAppearance, .isValid, LorenzConfiguration, .historyBytes, .isValid, LorenzPreset, .appearance, .camera (+10 more)

### Community 39 - "GeodesicPlayback"
Cohesion: 0.22
Nodes (3): .segments, GeodesicPlayback, GeodesicTrail

### Community 40 - "String"
Cohesion: 0.10
Nodes (20): WormholePresentation, .id, surface, .title, trajectories, wireframe, SurfaceError, .errorDescription (+12 more)

### Community 41 - "OptimizationStatus"
Cohesion: 0.22
Nodes (9): OptimizationStatus, converged, iterationLimit, lineSearchFailed, nonminimum, numericalLimit, ready, running (+1 more)

### Community 49 - "OptimizationMethod"
Cohesion: 0.33
Nodes (6): .isFinite, OptimizationMethod, gradient, .id, momentum, newton

### Community 50 - "LorenzRenderer"
Cohesion: 0.24
Nodes (3): Coordinator, LorenzRenderer, LorenzViewport

### Community 51 - "PlanarVectorField"
Cohesion: 0.21
Nodes (10): PlanarVectorField, .domain, .isValid, VectorField2D, .isValid, VectorIntegrationSettings, .isValid, linearFieldsMatchAnalyticSolutionsAndEquilibria() (+2 more)

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

### Community 57 - "VectorTrajectory"
Cohesion: 0.29
Nodes (5): VectorTrajectory, .canStep, .current, .steps, VectorTrajectoryPoint

### Community 59 - "GeodesicAppearance"
Cohesion: 0.25
Nodes (5): GeodesicAppearance, .isValid, GeodesicRenderTrack, geodesicOverlayPreservesSurfaceDepthAndFrozenHistory(), particleAndTrailAppearanceValidateScreenPointRanges()

### Community 60 - "CoordinateGrid"
Cohesion: 0.27
Nodes (6): CoordinateGrid, .isValid, .spacing, GridSegment, SurfaceVertex, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes()

### Community 61 - "CameraAction"
Cohesion: 0.25
Nodes (4): CameraAction, orbit, pan, zoom

### Community 62 - "VectorFieldPreset"
Cohesion: 0.22
Nodes (8): VectorFieldPreset, .defaultParameter, .formula, .id, oscillator, saddle, spiral, vanDerPol

### Community 63 - "VectorTrajectoryStatus"
Cohesion: 0.33
Nodes (6): VectorTrajectoryStatus, equilibrium, numericalLimit, ready, running, stepLimit

### Community 64 - "OptimizationError"
Cohesion: 0.40
Nodes (4): OptimizationError, invalidConfiguration, VectorIntegrationError, invalidConfiguration

## Knowledge Gaps
- **195 isolated node(s):** `.planarSession`, `.geodesicSession`, `.surfaceSession`, `.lorenzSession`, `.body` (+190 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 351 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **24 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `OrbitCamera`, `WorkspaceView`, `SurfaceMotionSession`, `WorkspaceCore`, `Sendable`, `EllisWormhole`, `GeodesicPlayback`, `SurfaceSession`, `TrailFade`, `GeodesicAppearance`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.planarSession`, `.geodesicSession`, `.surfaceSession` to the rest of the system?**
  _195 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.08536585365853659 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `OrbitCamera` to `LorenzParameters`, `WorkspaceView`, `WormholeSession`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `SurfaceSession`, `TrailFade`, `.draw`, `LorenzRenderer`, `CameraAction`, `simd`, `GeodesicSession`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `PlanarDomain` be split into smaller, more focused modules?**
  _Cohesion score 0.08502415458937199 - nodes in this community are weakly interconnected._