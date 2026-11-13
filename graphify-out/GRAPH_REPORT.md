# Graph Report - creative-math-ux01  (2026-11-13)

## Corpus Check
- 54 files · ~67,740 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 85 file(s) not represented in the graph (top: .log 80, (none) 1, .icns 1)
- WARNING: 85 of 196 files seen (43%) have no supported extractor and are missing from this graph entirely. It may look complete while representing only part of the codebase.

## Summary
- 967 nodes · 2336 edges · 55 communities (37 shown, 18 thin omitted)
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 422 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `961bf61d`
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
- RoundedWormhole
- FixedStepClock
- SurfaceSession
- TrailFade
- SurfaceRenderer
- PrimitiveRenderer
- MouseView
- SurfaceStyle
- LorenzSession
- WormholeLaunchStream
- LorenzValidationOptions
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
- OrbitCamera
- LorenzRenderer
- WorkspaceView
- CoordinateGrid
- WormholeLaunch
- WorkspaceCore
- LorenzPreset
- SurfacePreset
- String
- CameraAction
- verify.sh

## God Nodes (most connected - your core abstractions)
1. `WormholeSession` - 62 edges
2. `OrbitCamera` - 41 edges
3. `WormholeBeam` - 40 edges
4. `SurfaceMotionSession` - 33 edges
5. `EllisWormhole` - 33 edges
6. `GeodesicSession` - 32 edges
7. `TorusGeodesicConfiguration` - 32 edges
8. `WorkspaceCore` - 31 edges
9. `WorkspaceView` - 31 edges
10. `WormholeConfiguration` - 29 edges

## Surprising Connections (you probably didn't know these)
- `coordinateGridIsBoundedAndContainsAxesAndTicks()` --calls--> `CoordinateGrid`  [INFERRED]
  Tests/WorkspaceCoreTests/SurfaceTests.swift → Sources/WorkspaceCore/ParametricSurface.swift
- `benchmarkCLIRejectsSilentNoOutputAndUnknownOptions()` --calls--> `LorenzValidationOptions`  [INFERRED]
  Tests/WorkspaceCoreTests/LorenzTests.swift → Sources/WorkspaceCore/LorenzValidationOptions.swift
- `packedTransportStaysStableAlongLorenzTrajectory()` --calls--> `LorenzParameters`  [INFERRED]
  Tests/WorkspaceCoreTests/TrailGeometryTests.swift → Sources/WorkspaceCore/Lorenz.swift
- `geodesicOverlayPreservesSurfaceDepthAndFrozenHistory()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/GeodesicRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift
- `ellisRendererModesReuseGeometryAndDrawActualTrajectories()` --calls--> `GeodesicTrails`  [INFERRED]
  Tests/LorenzMetalTests/WormholeRenderingTests.swift → Sources/SurfaceMetal/GeodesicTrails.swift

## Import Cycles
- None detected.

## Communities (55 total, 18 thin omitted)

### Community 0 - ".run"
Cohesion: 0.17
Nodes (6): LorenzValidation, TimingSamples, ValidationError, .errorDescription, gpuFailure, referenceMismatch

### Community 1 - "LorenzParameters"
Cohesion: 0.20
Nodes (13): LorenzMath, LorenzParameters, .isValid, LorenzReference, gpuMatchesCPUReferenceAndResets(), equilibriumIsInvariantAndZAxisMatchesAnalyticDecay(), error(), lorenzDerivativeAndEquilibria() (+5 more)

### Community 2 - "WormholeSession"
Cohesion: 0.08
Nodes (21): .gallery, WormholeInspector, .body, WormholeSession, .appearance, .beam, .canAdvance, .depthTolerance (+13 more)

### Community 4 - "TorusGeodesicConfiguration"
Cohesion: 0.08
Nodes (29): simd, .segments, GeodesicAppearance, .isValid, GeodesicPlayback, GeodesicTrail, TorusGeodesicConfiguration, .initialState (+21 more)

### Community 5 - "SurfaceMotionSession"
Cohesion: 0.11
Nodes (8): SurfaceMotionSession, .canAdvance, .depthTolerance, .displayedParticle, .ellisAppearance, .ellisGeometry, .maximumRenderTracks, .renderBatch

### Community 6 - "EllisWormhole"
Cohesion: 0.10
Nodes (15): EllisWormhole, .axialScale, .camera, .isValid, LegacyFunnelProfile, .initialState, .isValid, .presentationPosition (+7 more)

### Community 7 - "WormholeBeam"
Cohesion: 0.13
Nodes (24): .renderedTrail, .selectedHasDisappeared, .selectedOutcome, .selectedPosition, RoundedWormholeComparison, WormholeBeam, .isValid, WormholeComparison (+16 more)

### Community 8 - "RoundedWormhole"
Cohesion: 0.15
Nodes (12): RoundedWormhole, .depth, .edge, RoundedWormholeSolver, .energyDrift, .surfaceError, .tangentError, RoundedWormholeTrack (+4 more)

### Community 9 - "FixedStepClock"
Cohesion: 0.33
Nodes (4): FixedStepClock, clockAccountsForDroppedTimeAndPreservesFractionalPhase(), clockBoundsCatchupAndValidatesSpeed(), clockIsRefreshIndependentAndPauseDoesNotAccumulate()

### Community 10 - "SurfaceSession"
Cohesion: 0.12
Nodes (11): SurfaceGalleryStudy, .body, SurfaceInspector, .body, SurfaceSession, .camera, .grid, .parameters (+3 more)

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
Cohesion: 0.14
Nodes (4): MouseView, .acceptsFirstResponder, .resizeCursor, PanelMouseRegion

### Community 15 - "SurfaceStyle"
Cohesion: 0.12
Nodes (16): LibraryCategory, all, dynamics, geometry, .id, WormholePresentation, .id, surface (+8 more)

### Community 16 - "LorenzSession"
Cohesion: 0.06
Nodes (22): CreativeMathApp, .body, FocusedValues, .geodesicSession, .lorenzSession, .surfaceSession, GeodesicSessionKey, LorenzCommands (+14 more)

### Community 17 - "WormholeLaunchStream"
Cohesion: 0.16
Nodes (10): .renderBatch, .selectedIsVisible, .summary, WormholeError, .errorDescription, invalidConfiguration, invalidStep, unstableIntegration (+2 more)

### Community 18 - "LorenzValidationOptions"
Cohesion: 0.16
Nodes (9): LorenzValidationOptions, OptionsError, .errorDescription, invalid, GeodesicError, .errorDescription, invalidConfiguration, unstableIntegration (+1 more)

### Community 20 - "SurfaceViewRenderer"
Cohesion: 0.17
Nodes (3): Coordinator, SurfaceViewport, SurfaceViewRenderer

### Community 21 - "LorenzGPU"
Cohesion: 0.15
Nodes (9): LorenzGPU, LorenzConfiguration, .historyBytes, .isValid, gpuRecoversFromNonFiniteInputWithoutConnectingOldTrail(), gpuRibbonFramesPreserveMathRenderAndFreezeWhenPaused(), gpuRingContentsAndPresetTransitions(), gpuStableDynamicsSettleWithoutRestarting() (+1 more)

### Community 23 - "SurfaceParameters"
Cohesion: 0.23
Nodes (9): SurfaceParameters, .formula, .isValid, SurfaceSample, analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents(), coordinateGridIsBoundedAndContainsAxesAndTicks(), meshBoundsSeamsAndParameterValidation(), torusSamplesSatisfyImplicitSurfaceAndPeriodicSeams() (+1 more)

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
Cohesion: 0.15
Nodes (16): WormholeConfiguration, .angularMomentum, .validationMessage, WormholePlayback, WormholeSolver, SurfaceMesh, ellisRendererModesReuseGeometryAndDrawActualTrajectories(), roundedMeshWeldsOneEdgeAndKeepsFiniteSurfaceSamples() (+8 more)

### Community 31 - "GeodesicSession"
Cohesion: 0.10
Nodes (13): GeodesicGalleryStudy, .body, GeodesicInspector, .body, GeodesicSession, .appearance, .configuration, .fade (+5 more)

### Community 32 - "OrbitCamera"
Cohesion: 0.08
Nodes (16): .body, DrawUniforms, LorenzTrails, CameraProjection, ParticleCameraTracking, RelaunchCameraTracking, .isTransitioning, OrbitCamera (+8 more)

### Community 33 - "LorenzRenderer"
Cohesion: 0.18
Nodes (3): Coordinator, LorenzRenderer, LorenzViewport

### Community 34 - "WorkspaceView"
Cohesion: 0.07
Nodes (35): CoreGraphics, GeodesicAxisLabels, .body, SurfaceAxisLabels, LibraryExperiment, WorkspaceView, .activeMotion, .body (+27 more)

### Community 35 - "CoordinateGrid"
Cohesion: 0.24
Nodes (6): CoordinateGrid, .isValid, .spacing, GridSegment, SurfaceVertex, surfaceRendererDrawsBothPresetsAndReusesUnchangedMeshes()

### Community 36 - "WormholeLaunch"
Cohesion: 0.22
Nodes (8): WormholeLaunch, crossing, deflection, .id, .impactRatio, nearCritical, .summary, .title

### Community 37 - "WorkspaceCore"
Cohesion: 0.07
Nodes (16): AppKit, Foundation, LorenzMetal, Metal, MetalKit, Observation, word(), Design (+8 more)

### Community 38 - "LorenzPreset"
Cohesion: 0.10
Nodes (20): LorenzAppearance, .isValid, LorenzError, .errorDescription, invalidConfiguration, metalUnavailable, resourceFailure, LorenzPreset (+12 more)

### Community 39 - "SurfacePreset"
Cohesion: 0.22
Nodes (8): SurfacePreset, .camera, .id, .parameters, .summary, .title, torus, wormhole

### Community 40 - "String"
Cohesion: 0.33
Nodes (5): SurfaceError, .errorDescription, invalidParameters, metalUnavailable, resourceFailure

### Community 41 - "CameraAction"
Cohesion: 0.50
Nodes (4): CameraAction, orbit, pan, zoom

### Community 53 - "verify.sh"
Cohesion: 0.67
Nodes (3): run_check(), verify.sh script, TMPDIR

## Knowledge Gaps
- **143 isolated node(s):** `.activeMotion`, `.studyDetails`, `all`, `dynamics`, `geometry` (+138 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 287 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WormholeSession` connect `WormholeSession` to `OrbitCamera`, `WorkspaceView`, `TorusGeodesicConfiguration`, `SurfaceMotionSession`, `WorkspaceCore`, `WormholeBeam`, `EllisWormhole`, `SurfaceSession`, `TrailFade`, `WormholeLaunchStream`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `WormholeSession` (e.g. with `WorkspaceView` and `.body`) actually correct?**
  _`WormholeSession` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `.activeMotion`, `.studyDetails`, `all` to the rest of the system?**
  _143 weakly-connected nodes found - possible missing edges._
- **Should `WormholeSession` be split into smaller, more focused modules?**
  _Cohesion score 0.08246225319396051 - nodes in this community are weakly interconnected._
- **Why does `OrbitCamera` connect `OrbitCamera` to `LorenzRenderer`, `WorkspaceView`, `WormholeSession`, `LorenzParameters`, `SurfaceMotionSession`, `EllisWormhole`, `LorenzPreset`, `SurfacePreset`, `SurfaceSession`, `TrailFade`, `SurfaceRenderer`, `Sendable`, `GeodesicSession`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `OrbitCamera` (e.g. with `cameraProjectionPreservesAxesDepthAndAspect()` and `cameraCanFocusATargetWithoutChangingExistingZoomLimits()`) actually correct?**
  _`OrbitCamera` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Should `TorusGeodesicConfiguration` be split into smaller, more focused modules?**
  _Cohesion score 0.0773405698778833 - nodes in this community are weakly interconnected._