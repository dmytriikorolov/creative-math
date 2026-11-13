# Graph Report - creative-math  (2026-11-13)

## Corpus Check
- 54 files · ~66,544 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 80 file(s) not represented in the graph (top: .log 75, (none) 1, .icns 1)
- WARNING: 80 of 185 files seen (43%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 954 nodes · 2308 edges · 55 communities (39 shown, 16 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 421 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- .run
- LorenzParameters
- WormholeSession
- CameraMetalView
- TorusGeodesicConfiguration
- SurfaceMotionSession
- EllisWormhole
- WormholeBeam
- Testing
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
- TrajectorySnapshot
- LorenzPreset
- Foundation
- GeodesicAppearance
- CameraAction
- .gallery
- OrbitCamera
- NumericControl
- .matrix
- verify.sh
- SurfaceAxisLabels

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 40 edges
4. `EllisWormhole` - 33 edges
5. `SurfaceMotionSession` - 33 edges
6. `GeodesicSession` - 32 edges
7. `TorusGeodesicConfiguration` - 32 edges
8. `WorkspaceCore` - 31 edges
9. `WorkspaceView` - 29 edges
10. `WormholeConfiguration` - 29 edges

## Surprising Connections (you probably didn't know these)
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `packedTransportStaysStableAlongLorenzTrajectory()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/TrailGeometryTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `gpuMatchesCPUReferenceAndResets()` --calls--> `LorenzReference`  [INFERRED]
  Tests/LorenzMetalTests/LorenzGPUTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()` --calls--> `LorenzValidationOptions`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/LorenzValidationOptions.swift
- `geodesicOverlayPreservesSurfaceDepthAndFrozenHistory()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/GeodesicRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift

## Import Cycles
- None detected.

## Communities (55 total, 16 thin omitted)

### Community 0 - ".run"
Cohesion: 0.07
Nodes (20): LorenzValidation, TimingSamples, ValidationError, .errorDescription, gpuFailure, referenceMismatch, LorenzValidationOptions, OptionsError (+12 more)

### Community 1 - "LorenzParameters"
Cohesion: 0.19
Nodes (12): LorenzMath, LorenzParameters, .isValid, LorenzReference, equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria(), parameterValidationAndStableReference() (+4 more)

### Community 2 - "WormholeSession"
Cohesion: 0.07
Nodes (24): WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance, .displayedParticle (+16 more)

### Community 4 - "TorusGeodesicConfiguration"
Cohesion: 0.22
Nodes (14): TorusGeodesicConfiguration, .isValid, TorusGeodesicSolver, equatorialGeodesicsTraceActualCirclesOverMultipleLaps(), extendedGeodesicsStayFiniteOnSurfaceWithMeasuredDrift(), geodesicClockIsIndependentOfDisplayRefresh(), integrationRestartBatchingAndRingHistoryAreDeterministic(), invalidGeodesicInputsAreRejected() (+6 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.10
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.08
Nodes (29): simd, EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, WormholeConfiguration, .angularMomentum (+21 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.06
Nodes (48): .renderBatch, .renderedTrail, .selectedHasDisappeared, .selectedIsVisible, .selectedOutcome, .selectedPosition, .summary, WormholeError (+40 more)

### Community 8 - "Testing"
Cohesion: 0.36
Nodes (4): LorenzMetal, Metal, SurfaceMetal, Testing

### Community 9 - "FixedStepClock"
Cohesion: 0.33
Nodes (4): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate()

### Community 10 - "SurfaceSession"
Cohesion: 0.10
Nodes (19): .body, SurfaceSession, .camera, .grid, .parameters, .preset, .style, .surfaceDensity (+11 more)

### Community 11 - "TrailFade"
Cohesion: 0.09
Nodes (13): GeodesicTrails, GeodesicUniforms, RibbonGeometry, TrailFade, .isValid, geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce(), fadeDelayDurationAndSmoothBoundaries(), fadeDrawRangeNeverOmitsANonzeroEndpoint() (+5 more)

### Community 12 - "SurfaceRenderer"
Cohesion: 0.14
Nodes (6): GridVertex, SurfaceMeshKey, ellis, parametric, SurfaceRenderer, SurfaceUniforms

### Community 13 - "PrimitiveRenderer"
Cohesion: 0.13
Nodes (7): Coordinator, MetalViewport, PrimitiveRenderer, RenderError, .errorDescription, unavailable, .studyPreview

### Community 14 - "MouseView"
Cohesion: 0.15
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "SurfaceStyle"
Cohesion: 0.10
Nodes (19): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title (+11 more)

### Community 16 - "LorenzSession"
Cohesion: 0.15
Nodes (8): LorenzGalleryStudy, .body, .body, LorenzSession, .appearance, .configuration, .isPaused, .speed

### Community 17 - "GeodesicPlayback"
Cohesion: 0.23
Nodes (3): .segments, GeodesicPlayback, GeodesicTrail

### Community 18 - "TorusMetric"
Cohesion: 0.23
Nodes (7): .initialState, .initialState, .position, .relativeSpeedDrift, TorusMetric, .isValid, torusMetricAndAccelerationMatchGeometry()

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.19
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 21 - "LorenzGPU"
Cohesion: 0.16
Nodes (10): LorenzGPU, LorenzConfiguration, .historyBytes, .isValid, gpuMatchesCPUReferenceAndResets(), gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused(), gpuRingContentsAndPresetTransitions() (+2 more)

### Community 23 - "SurfaceParameters"
Cohesion: 0.14
Nodes (12): CoordinateGrid, .isValid, .spacing, GridSegment, SurfaceSample, SurfaceVertex, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes(), analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents() (+4 more)

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
Cohesion: 0.27
Nodes (3): ParticleCameraTracking, followCameraRespectsPausedStepRestartAndInvalidTargets(), followCameraTracksEveryStepWithoutRotatingOrZooming()

### Community 31 - "GeodesicSession"
Cohesion: 0.12
Nodes (10): .body, GeodesicSession, .appearance, .configuration, .fade, .isFollowing, .isPaused, .playbackRate (+2 more)

### Community 32 - ".encode"
Cohesion: 0.15
Nodes (4): DrawUniforms, LorenzTrails, cameraProjectionPreservesAxesDepthAndAspect(), surfaceCameraProjectionMatchesExistingLorenzConvention()

### Community 33 - "LorenzRenderer"
Cohesion: 0.17
Nodes (3): Coordinator, LorenzRenderer, LorenzViewport

### Community 34 - "WorkspaceView"
Cohesion: 0.07
Nodes (33): CoreGraphics, GeodesicInspector, LorenzInspector, SurfaceInspector, WorkspaceView, .activeMotion, .body, .studyDetails (+25 more)

### Community 35 - "CreativeMathApp.swift"
Cohesion: 0.15
Nodes (11): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .surfaceSession, GeodesicSessionKey, LorenzCommands (+3 more)

### Community 36 - "WorkspaceCore"
Cohesion: 0.24
Nodes (4): MetalKit, Design, SwiftUI, WorkspaceCore

### Community 38 - "LorenzPreset"
Cohesion: 0.10
Nodes (20): LorenzAppearance, .isValid, LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, LorenzPreset (+12 more)

### Community 39 - "Foundation"
Cohesion: 0.24
Nodes (4): AppKit, Foundation, Observation, word()

### Community 40 - "GeodesicAppearance"
Cohesion: 0.23
Nodes (5): GeodesicAppearance, .isValid, GeodesicRenderTrack, geodesicOverlayPreservesSurfaceDepthAndFrozenHistory(), particleAndTrailAppearanceValidateScreenPointRanges()

### Community 41 - "CameraAction"
Cohesion: 0.50
Nodes (4): CameraAction, orbit, pan, zoom

### Community 49 - ".gallery"
Cohesion: 0.20
Nodes (7): GeodesicGalleryStudy, .body, SurfaceGalleryStudy, .body, .gallery, WormholeGalleryStudy, .body

### Community 50 - "OrbitCamera"
Cohesion: 0.42
Nodes (3): OrbitCamera, cameraCanFocusATargetWithoutChangingExistingZoomLimits(), cameraLimitsAndSimulationIndependence()

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

### Community 54 - "SurfaceAxisLabels"
Cohesion: 0.50
Nodes (4): GeodesicAxisLabels, .body, SurfaceAxisLabels, .body

## Knowledge Gaps
- **139 isolated node(s):** `TMPDIR`, `.errorDescription`, `gpuFailure`, `referenceMismatch`, `.isValid` (+134 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 281 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `WorkspaceView`, `SurfaceMotionSession`, `EllisWormhole`, `WormholeBeam`, `Foundation`, `GeodesicAppearance`, `SurfaceSession`, `TrailFade`, `GeodesicPlayback`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `TMPDIR`, `.errorDescription`, `gpuFailure` to the rest of the system?**
  _139 weakly-connected nodes found - possible missing edges._
- **Should `.run` be split into smaller, more focused modules?**
  _Cohesion score 0.07179487179487179 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `OrbitCamera` to `.encode`, `LorenzRenderer`, `WormholeSession`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `.matrix`, `SurfaceAxisLabels`, `Sendable`, `GeodesicSession`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.07142857142857142 - nodes in this community are weakly interconnected._