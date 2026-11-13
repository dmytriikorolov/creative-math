# Graph Report - creative-math  (2026-11-13)

## Corpus Check
- 54 files · ~68,336 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 90 file(s) not represented in the graph (top: .log 85, (none) 1, .icns 1)
- WARNING: 90 of 206 files seen (44%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 968 nodes · 2342 edges · 60 communities (38 shown, 22 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 427 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cde564a2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- .run
- LorenzParameters
- WormholeSession
- CameraMetalView
- TorusGeodesicConfiguration
- SurfaceMotionSession
- EllisWormhole
- WormholeBeam
- TorusMetric
- FixedStepClock
- SurfaceSession
- TrailFade
- SurfaceRenderer
- PrimitiveRenderer
- MouseView
- SurfaceStyle
- LorenzSession
- GeodesicPlayback
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
- LorenzRenderer
- WorkspaceView
- CreativeMathApp.swift
- WorkspaceCore
- WorkspaceCore
- LorenzPreset
- Foundation
- GeodesicAppearance
- CameraAction
- LocalizedError
- verify.sh
- GeodesicAppearance
- TrajectorySnapshot
- LorenzViewport
- ParticleCameraTracking
- word

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 41 edges
4. `SurfaceMotionSession` - 33 edges
5. `EllisWormhole` - 33 edges
6. `GeodesicSession` - 32 edges
7. `TorusGeodesicConfiguration` - 32 edges
8. `WorkspaceCore` - 31 edges
9. `WorkspaceView` - 31 edges
10. `WormholeComparison` - 30 edges

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

## Communities (60 total, 22 thin omitted)

### Community 1 - "LorenzParameters"
Cohesion: 0.22
Nodes (9): LorenzMath, LorenzParameters, .isValid, LorenzReference, gpuMatchesCPUReferenceAndResets(), parameterValidationAndStableReference(), seededResetAndBatchingAreRepeatable(), stableDynamicsConvergeWithoutRecoveryOrForcedMotion() (+1 more)

### Community 2 - "WormholeSession"
Cohesion: 0.07
Nodes (23): .gallery, WormholeGalleryStudy, .body, WormholeInspector, .body, WormholeSession, .appearance, .beam (+15 more)

### Community 4 - "TorusGeodesicConfiguration"
Cohesion: 0.22
Nodes (14): TorusGeodesicConfiguration, .isValid, TorusGeodesicSolver, equatorialGeodesicsTraceActualCirclesOverMultipleLaps(), extendedGeodesicsStayFiniteOnSurfaceWithMeasuredDrift(), geodesicClockIsIndependentOfDisplayRefresh(), integrationRestartBatchingAndRingHistoryAreDeterministic(), invalidGeodesicInputsAreRejected() (+6 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.10
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.09
Nodes (28): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum, .initialState (+20 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.06
Nodes (49): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+41 more)

### Community 8 - "TorusMetric"
Cohesion: 0.24
Nodes (6): .initialState, .position, .relativeSpeedDrift, TorusMetric, .isValid, torusMetricAndAccelerationMatchGeometry()

### Community 9 - "FixedStepClock"
Cohesion: 0.20
Nodes (8): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate(), equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria(), rk4MatchesIndependentDOP853AndConverges()

### Community 10 - "SurfaceSession"
Cohesion: 0.17
Nodes (8): .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style, .surfaceDensity

### Community 11 - "TrailFade"
Cohesion: 0.09
Nodes (13): GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint() (+5 more)

### Community 12 - "SurfaceRenderer"
Cohesion: 0.13
Nodes (6): GridVertex, SurfaceMeshKey, ellis, parametric, SurfaceRenderer, SurfaceUniforms

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.12
Nodes (8): MetalKit, Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "SurfaceStyle"
Cohesion: 0.12
Nodes (16): LibraryCategory, all, dynamics, geometry, .id, WormholePresentation, .id, surface (+8 more)

### Community 16 - "LorenzSession"
Cohesion: 0.06
Nodes (22): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .surfaceSession, GeodesicSessionKey, LorenzCommands (+14 more)

### Community 17 - "GeodesicPlayback"
Cohesion: 0.23
Nodes (3): .segments, GeodesicPlayback, GeodesicTrail

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
Cohesion: 0.31
Nodes (5): SurfaceSample, analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents(), meshBoundsSeamsAndParameterValidation(), torusSamplesSatisfyImplicitSurfaceAndPeriodicSeams(), wormholeHasOpenThroatFixedRimAndContinuousFlatLimit()

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
Cohesion: 0.43
Nodes (3): GridSegment, SurfaceMesh, SurfaceVertex

### Community 31 - "GeodesicSession"
Cohesion: 0.12
Nodes (10): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+2 more)

### Community 32 - ".encode"
Cohesion: 0.08
Nodes (13): DrawUniforms, LorenzTrails, CameraProjection, RelaunchCameraTracking, .isTransitioning, OrbitCamera, cameraProjectionPreservesAxesDepthAndAspect(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused() (+5 more)

### Community 34 - "WorkspaceView"
Cohesion: 0.05
Nodes (43): CoreGraphics, Design, GeodesicGalleryStudy, .body, GeodesicInspector, SurfaceGalleryStudy, .body, SurfaceInspector (+35 more)

### Community 35 - "CreativeMathApp.swift"
Cohesion: 0.29
Nodes (5): CoordinateGrid, .isValid, .spacing, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes(), coordinateGridIsBoundedAndContainsAxesAndTicks()

### Community 36 - "WorkspaceCore"
Cohesion: 0.22
Nodes (8): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title

### Community 37 - "WorkspaceCore"
Cohesion: 0.17
Nodes (9): AppKit, Foundation, LorenzMetal, Metal, Observation, simd, SurfaceMetal, Testing (+1 more)

### Community 38 - "LorenzPreset"
Cohesion: 0.12
Nodes (15): LorenzAppearance, .isValid, LorenzPreset, .appearance, .camera, classic, .configuration, filament (+7 more)

### Community 39 - "Foundation"
Cohesion: 0.20
Nodes (11): SurfaceParameters, .formula, .isValid, SurfacePreset, .camera, .id, .parameters, .summary (+3 more)

### Community 40 - "GeodesicAppearance"
Cohesion: 0.33
Nodes (5): SurfaceError, .errorDescription, invalidParameters, metalUnavailable, resourceFailure

### Community 41 - "CameraAction"
Cohesion: 0.50
Nodes (4): CameraAction, orbit, pan, zoom

### Community 49 - "LocalizedError"
Cohesion: 0.13
Nodes (13): ValidationError, .errorDescription, gpuFailure, referenceMismatch, LorenzError, .errorDescription, invalidConfiguration, metalUnavailable (+5 more)

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

### Community 55 - "GeodesicAppearance"
Cohesion: 0.23
Nodes (5): GeodesicAppearance, .isValid, GeodesicRenderTrack, geodesicOverlayPreservesSurfaceDepthAndFrozenHistory(), particleAndTrailAppearanceValidateScreenPointRanges()

### Community 58 - "ParticleCameraTracking"
Cohesion: 0.40
Nodes (3): ParticleCameraTracking, followCameraRespectsPausedStepRestartAndInvalidTargets(), followCameraTracksEveryStepWithoutRotatingOrZooming()

## Knowledge Gaps
- **143 isolated node(s):** `.activeMotion`, `.studyDetails`, `all`, `dynamics`, `geometry` (+138 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 287 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **22 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `.encode`, `WorkspaceView`, `SurfaceMotionSession`, `WorkspaceCore`, `WormholeBeam`, `EllisWormhole`, `SurfaceSession`, `TrailFade`, `GeodesicPlayback`, `GeodesicAppearance`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.activeMotion`, `.studyDetails`, `all` to the rest of the system?**
  _143 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.07293868921775898 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `.encode` to `LorenzRenderer`, `WorkspaceView`, `WormholeSession`, `LorenzParameters`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `Foundation`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `ParticleCameraTracking`, `Sendable`, `GeodesicSession`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `SurfaceMotionSession` be split into smaller, more focused modules?**
  _Cohesion score 0.10276679841897234 - nodes in this community are weakly interconnected._