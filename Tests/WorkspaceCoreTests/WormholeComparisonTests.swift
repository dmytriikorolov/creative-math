import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func restoredFunnelMatchesAcceptedSurfaceAndItsInducedMetric() {
    let geometry = WormholeBeam().geometry
    var original = SurfacePreset.wormhole.parameters
    original.throat = geometry.throatRadius; original.depth = 7; original.radius = 10
    let limit = acosh(original.radius/original.throat)
    for u in [0.0,0.17,0.5,1] { for v in [0.0,0.25,0.7,1] {
        let l = original.throat*sinh(v*limit)
        #expect(simd_length(geometry.displayPosition(l: l,phi: u*2 * .pi)-original.sample(u: u,v: v).position) < 1e-12)
    } }
    for l in [-30.0,-2,0,2,30] {
        let h = 1e-5, phi = 0.4
        let dl = (geometry.position(l: l+h,phi: phi)-geometry.position(l: l-h,phi: phi))/(2*h)
        let dp = (geometry.position(l: l,phi: phi+h)-geometry.position(l: l,phi: phi-h))/(2*h)
        #expect(abs(dot(dl,dl)-geometry.metric(l: l).x) < 1e-8)
        #expect(abs(dot(dp,dp)-geometry.metric(l: l).y) < 1e-6)
        #expect(abs(dot(dl,dp)) < 1e-8)
        let state = SIMD4<Double>(l,phi,-0.5,0.2), derivative = geometry.derivative(SIMD4<Double>(l,phi,-0.5,0.2))
        let a = geometry.throatRadius, b = geometry.axialScale, g = l*l+a*a
        let ePrime = 2*l*(a*a-b*b)/(g*g)
        let energyDerivative = ePrime*state.z*state.z*state.z+2*geometry.metric(l: l).x*state.z*derivative.z+2*l*state.z*state.w*state.w+2*g*state.w*derivative.w
        #expect(abs(energyDerivative) < 1e-12)
    }
}

@Test func parallelStartsHaveSameHeadingAndUnitSurfaceSpeed() throws {
    let beam = WormholeBeam()
    #expect(beam.starts.count == 13 && beam.isValid)
    var momenta: [Double] = []
    for index in beam.starts.indices {
        let c = try beam.launch(index), state = c.initialState, r = c.geometry.radius(l: state.x)
        let planarX = state.x/r*cos(state.y)*state.z-r*sin(state.y)*state.w
        let planarZ = state.x/r*sin(state.y)*state.z+r*cos(state.y)*state.w
        #expect(planarX > 0 && abs(planarZ) < 1e-13)
        #expect(abs(c.geometry.energy(state)-1) < 1e-13)
        momenta.append(c.angularMomentum)
    }
    #expect(abs(momenta[6]) < 1e-12 && abs(momenta[0]) > beam.geometry.throatRadius)
}

@Test func comparisonProducesCrossingsAndDeflectionsThenRetiresEscapedTracks() throws {
    let beam = WormholeBeam()
    var simulation = try WormholeComparison(beam: beam,trailLength: 512)
    for _ in 0..<1200 { try simulation.advance(elapsed: 1.0/60,paused: false,rate: 4) }
    let through = simulation.tracks.filter { $0.solver.state.x < 0 }.count
    let deflected = simulation.tracks.filter { $0.solver.state.x > 0 && $0.solver.state.z > 0 }.count
    print("FUNNEL_COMPARISON s=80 balls=13 through=\(through) deflected=\(deflected)")
    #expect(through == 5 && deflected == 8)
    for track in simulation.tracks {
        #expect(track.hasDisappeared && track.solver.steps < 19200 && !track.isPaused)
        #expect(max(abs(track.solver.position.x),abs(track.solver.position.z)) > beam.geometry.funnel!.fieldHalfExtent+4)
        #expect(track.trail.count == 512 && abs(track.solver.energyDrift) < 1e-7 && abs(track.solver.momentumDrift) < 1e-7)
    }
    let before = simulation.tracks.map { $0.solver.steps }
    try simulation.advance(elapsed: 1.0/60,paused: false,rate: 4)
    #expect(zip(before,simulation.tracks).allSatisfy { $0.1.solver.steps == $0.0 })
    try simulation.advance(elapsed: 100,paused: true,rate: 4)
    let frozen = simulation.tracks.map { $0.solver.state }
    try simulation.advance(elapsed: 100,paused: true,rate: 4)
    #expect(simulation.tracks.map { $0.solver.state } == frozen)
    try simulation.restart(paused: true)
    #expect(simulation.tracks.allSatisfy { $0.solver.steps == 0 && $0.trail.count == 1 })
    try simulation.singleStep(paused: true)
    #expect(simulation.tracks.allSatisfy { $0.solver.steps == 1 })
}

@Test func changingOneStartingPointChangesTheOutcomeWithoutChangingHeading() throws {
    var beam = WormholeBeam()
    let central = try beam.launch(6)
    beam.starts[6].y = 4
    let shifted = try beam.launch(6)
    #expect(abs(central.angularMomentum) < central.geometry.throatRadius)
    #expect(abs(shifted.angularMomentum) > shifted.geometry.throatRadius)
    var a = try WormholeSolver(configuration: central), b = try WormholeSolver(configuration: shifted)
    try a.advance(steps: 14400); try b.advance(steps: 14400)
    #expect(a.state.x < 0 && b.state.x > 0 && b.state.z > 0)
    beam.starts[6] = .zero
    #expect(!beam.isValid)
    #expect(throws: WormholeError.self) { try WormholeComparison(beam: beam) }
}

@Test func fasterWormholePlaybackKeepsFixedStepsAndCatchUpBound() throws {
    var fast = try WormholeComparison(beam: WormholeBeam(),trailLength: 256)
    var reference = try WormholeSolver(configuration: WormholeBeam().launch(6))
    try fast.advance(elapsed: 1.0/60,paused: false,rate: 8)
    try reference.advance(steps: 32)
    #expect(fast.tracks[6].solver.state == reference.state)
    #expect(fast.tracks.allSatisfy { $0.solver.steps == 32 })
    try fast.advance(elapsed: 1,paused: false,rate: 16)
    #expect(fast.tracks.allSatisfy { $0.solver.steps == 96 && $0.clock.discardedTime > 0 })
    #expect(throws: WormholeError.self) { try fast.advance(elapsed: 1.0/60,paused: false,rate: 17) }
}

@Test func roundedReturnSurfaceHasConsistentDerivativesAndJoinedSheets() {
    let surface = RoundedWormhole(geometry: WormholeBeam().geometry)
    for x in [2.0,17.9,18.0,18.1,27,35.9,36] {
        let p = surface.position(x: x,z: 1,upper: true)
        let d = surface.differential(at: p), h = 1e-4
        #expect(abs(d.value) < 1e-10)
        #expect(abs(simd_length(surface.normal(at: p))-1) < 1e-12)
        for axis in 0..<3 {
            var delta = SIMD3<Double>.zero; delta[axis] = h
            let left = surface.differential(at: p-delta), right = surface.differential(at: p+delta)
            #expect(abs((right.value-left.value)/(2*h)-d.gradient[axis]) < 1e-5)
            #expect(simd_length((right.gradient-left.gradient)/(2*h)-d.hessian[axis]) < 1e-5)
        }
    }
    for z in [-36.0,-5,0,5,36] {
        let upper = surface.position(x: surface.edge,z: z,upper: true), lower = surface.position(x: surface.edge,z: z,upper: false)
        #expect(upper == lower)
        #expect(simd_length(surface.normal(at: upper)-SIMD3<Double>(1,0,0)) < 1e-12)
    }
    // The original shape is preserved before the broad return strip of the +X edge.
    let g = WormholeBeam().geometry, l = 18.0, phi = 0.7
    let original = g.displayPosition(l: l,phi: phi)
    #expect(simd_length(surface.position(x: original.x,z: original.z,upper: true)-original) < 1e-12)
}

@Test func roundedReturnGeodesicsTraverseTheEdgeWithoutBounceOrReseed() throws {
    var beam = WormholeBeam(); beam.starts = [SIMD2(22,0)]; beam.heading = 0
    var solver = try RoundedWormholeSolver(beam: beam,index: 0)
    let initial = solver.position
    var crossed = false, largestError = 0.0
    for _ in 0..<14400 {
        try solver.advance()
        crossed = crossed || (solver.position.y < -7 && solver.position.x > 20)
        largestError = max(largestError,max(solver.surfaceError,abs(solver.energyDrift)))
        #expect(solver.position.x <= solver.surface.edge+1e-5)
    }
    print("ROUNDED_EDGE s=60 maximum_constraint_or_energy_error=\(largestError)")
    #expect(crossed && solver.steps == 14400 && solver.position != initial)
    #expect(largestError < 1e-5)
    var repeated = try RoundedWormholeSolver(beam: beam,index: 0)
    for _ in 0..<14400 { try repeated.advance() }
    #expect(repeated.position == solver.position && repeated.velocity == solver.velocity)
    var comparison = try RoundedWormholeComparison(beam: beam,trailLength: 256)
    try comparison.advance(elapsed: 1.0/60,paused: false,rate: 8)
    #expect(comparison.tracks[0].solver.steps == 32)
    let frozen = comparison.tracks[0].solver.position
    try comparison.advance(elapsed: 100,paused: true,rate: 8)
    #expect(comparison.tracks[0].solver.position == frozen)
    try comparison.step()
    #expect(comparison.tracks[0].solver.steps == 33)
}

@Test func roundedMeshWeldsOneEdgeAndKeepsFiniteSurfaceSamples() throws {
    var geometry = WormholeBeam().geometry
    geometry.funnel?.roundedReturnEdge = true
    let surface = RoundedWormhole(geometry: geometry)
    let columns = 192, rows = 128
    let mesh = try SurfaceMesh(ellis: geometry)
    #expect(mesh.vertices.count == (columns+1)*(rows+1))
    #expect(mesh.indices.allSatisfy { Int($0) < mesh.vertices.count })
    for vertex in mesh.vertices {
        let p = SIMD3<Double>(SIMD3(vertex.position.x,vertex.position.y,vertex.position.z))
        #expect(abs(surface.differential(at: p).value) < 1e-4)
        #expect(abs(simd_length(vertex.normal)-1) < 1e-5)
    }
    // Column 0 is +X; the upper endpoint shares the lower endpoint's index.
    #expect(!mesh.indices.contains(UInt32(rows*(columns+1))))
    #expect(mesh.vertices[0].position == mesh.vertices[rows*(columns+1)].position)
    // At -X, the two sheet boundaries remain separate and open.
    #expect(mesh.vertices[columns/2].position != mesh.vertices[rows*(columns+1)+columns/2].position)
    #expect(throws: WormholeError.self) { try WormholeSolver(configuration: {
        var c = WormholeConfiguration(); c.geometry = geometry; return c
    }()) }
}

@Test func roundedSolverConvergesAndHandlesShapeExtremes() throws {
    var beam = WormholeBeam(); beam.starts = [SIMD2(22,2)]
    func endpoint(_ dt: Double) throws -> SIMD3<Double> {
        var solver = try RoundedWormholeSolver(beam: beam,index: 0)
        for _ in 0..<Int((24/dt).rounded()) { try solver.advance(dt: dt) }
        return solver.position
    }
    let reference = try endpoint(1.0/960)
    let coarse = simd_length(try endpoint(1.0/60)-reference)
    let fine = simd_length(try endpoint(1.0/120)-reference)
    print("ROUNDED_CONVERGENCE coarse=\(coarse) fine=\(fine)")
    #expect(fine < coarse/8)
    for throat in [1.0,4] { for depth in [2.0,12] {
        beam.geometry.throatRadius = throat; beam.geometry.funnel?.depth = depth
        var solver = try RoundedWormholeSolver(beam: beam,index: 0)
        for _ in 0..<28800 { try solver.advance() }
        #expect(abs(solver.energyDrift) < 1e-5 && solver.surfaceError < 1e-5 && solver.tangentError < 1e-5)
    } }
    var track = try RoundedWormholeTrack(beam: beam,index: 0,trailLength: 256)
    for _ in 0..<120 { try track.advance(elapsed: 1.0/60,paused: false,rate: 8) }
    #expect(track.trail.count == 256)
    #expect(abs(track.solver.surface.differential(at: track.presentationPosition).value) < 1e-9)
}

@Test func roundedDefaultBeamRemainsStableAcrossReturnPasses() throws {
    let beam = WormholeBeam()
    var comparison = try RoundedWormholeComparison(beam: beam,trailLength: 256)
    for _ in 0..<500 { try comparison.advance(elapsed: 1.0/60,paused: false,rate: 16) }
    for track in comparison.tracks {
        #expect((track.hasDisappeared || track.solver.steps == 32000) && track.trail.count == 256)
        #expect(track.solver.position.x <= track.solver.surface.edge+1e-5)
        #expect(abs(track.solver.energyDrift) < 1e-5 && track.solver.surfaceError < 1e-5)
    }
    var invalid = beam; invalid.starts[0].x = 36
    #expect(throws: WormholeError.self) { try RoundedWormholeComparison(beam: invalid,trailLength: 256) }
}

@Test func widerReturnHasRoomForARoundedTurn() {
    let surface = RoundedWormhole(geometry: WormholeBeam().geometry)
    #expect(surface.edge == 36)
    #expect(surface.width > 9 && surface.width < 12)
    let start = surface.edge-surface.width
    let p = surface.position(x: start,z: 0,upper: true)
    let normal = surface.normal(at: p)
    #expect(abs(normal.x/normal.y) < 0.2)
    let upper = surface.position(x: surface.edge,z: 0,upper: true)
    #expect(upper == surface.position(x: surface.edge,z: 0,upper: false))
}

@Test func escapedBallsRetireIndependentlyAndRestartRestoresThem() throws {
    var beam = WormholeBeam()
    beam.starts = [SIMD2(-31,0),SIMD2(-18,0)]; beam.heading = .pi
    var open = try WormholeComparison(beam: beam,trailLength: 256)
    var rounded = try RoundedWormholeComparison(beam: beam,trailLength: 256)
    for _ in 0..<40 {
        try open.advance(elapsed: 1.0/60,paused: false,rate: 16)
        try rounded.advance(elapsed: 1.0/60,paused: false,rate: 16)
    }
    #expect(open.tracks[0].hasDisappeared && !open.tracks[1].hasDisappeared)
    #expect(rounded.tracks[0].hasDisappeared && !rounded.tracks[1].hasDisappeared)
    let openSteps = open.tracks.map { $0.solver.steps }
    let roundedSteps = rounded.tracks.map { $0.solver.steps }
    try open.singleStep(paused: true); try rounded.step()
    #expect(open.tracks[0].solver.steps == openSteps[0])
    #expect(rounded.tracks[0].solver.steps == roundedSteps[0])
    #expect(open.tracks[1].solver.steps == openSteps[1]+1)
    #expect(rounded.tracks[1].solver.steps == roundedSteps[1]+1)
    try open.restart(paused: true)
    rounded = try RoundedWormholeComparison(beam: beam,trailLength: 256)
    #expect(open.tracks.allSatisfy { !$0.hasDisappeared && $0.solver.steps == 0 })
    #expect(rounded.tracks.allSatisfy { !$0.hasDisappeared && $0.solver.steps == 0 })
}

@Test func roundedReturnUsesAnEllipticalSectionWithASmoothApproach() {
    let geometry = WormholeBeam().geometry, surface = RoundedWormhole(geometry: WormholeBeam().geometry)
    let x = surface.edge-surface.width*0.4
    let originalHeight = geometry.axialScale*acosh(x/geometry.throatRadius)
    #expect(abs(surface.heightSquared(x: x,z: 0)/(originalHeight*originalHeight)-0.64) < 1e-12)
}


@Test func continuousLaunchesRecycleOnlyEscapedSlotsAndRepeatTheSeed() throws {
    var beam = WormholeBeam(); beam.starts = [SIMD2(-31,0),SIMD2(-18,0)]; beam.heading = .pi
    var settings = WormholeLaunchSettings(); settings.continuous = true; settings.startTogether = false
    var open = try WormholeComparison(beam: beam,trailLength: 256,launches: settings)
    var rounded = try RoundedWormholeComparison(beam: beam,trailLength: 256,launches: settings)
    #expect(!open.isVisible(0) && !open.isVisible(1))
    try open.singleStep(paused: true); try rounded.step()
    #expect(open.isVisible(0) && !open.isVisible(1))
    #expect(rounded.isVisible(0) && !rounded.isVisible(1))
    let initial = open.tracks[0].solver.state
    for _ in 0..<300 {
        let oldOpen = open.tracks, oldRounded = rounded.tracks
        let openGenerations = open.stream.generations, roundedGenerations = rounded.stream.generations
        try open.advance(elapsed: 1.0/60,paused: false,rate: 16)
        try rounded.advance(elapsed: 1.0/60,paused: false,rate: 16)
        for i in beam.starts.indices {
            if open.stream.generations[i] != openGenerations[i] {
                #expect(oldOpen[i].hasDisappeared || openGenerations[i] == 0)
                #expect(open.tracks[i].trail.count <= 65)
            }
            if rounded.stream.generations[i] != roundedGenerations[i] {
                #expect(oldRounded[i].hasDisappeared || roundedGenerations[i] == 0)
                #expect(rounded.tracks[i].trail.count <= 65)
            }
        }
        #expect(open.tracks.count == 2 && rounded.tracks.count == 2)
    }
    #expect(open.stream.generations.allSatisfy { $0 > 1 })
    #expect(rounded.stream.generations.allSatisfy { $0 > 1 })
    let generations = open.stream.generations, states = open.tracks.map { $0.solver.state }
    try open.advance(elapsed: 100,paused: true,rate: 16)
    #expect(open.stream.generations == generations && open.tracks.map { $0.solver.state } == states)
    try open.restart(paused: true); try open.singleStep(paused: true)
    #expect(open.tracks[0].solver.state == initial && !open.isVisible(1))
    let repeated = try RoundedWormholeComparison(beam: beam,trailLength: 256,launches: settings)
    #expect(repeated.stream.generations == [0,0])
}

@Test func continuousLaunchesAreIndependentOfRenderCadence() throws {
    var beam = WormholeBeam(); beam.starts = [SIMD2(-31,0),SIMD2(-18,0)]; beam.heading = .pi
    var settings = WormholeLaunchSettings(); settings.continuous = true; settings.startTogether = false
    var a = try WormholeComparison(beam: beam,trailLength: 256,launches: settings)
    var b = a
    var ra = try RoundedWormholeComparison(beam: beam,trailLength: 256,launches: settings)
    var rb = ra
    for _ in 0..<2400 {
        try a.advance(elapsed: 4*FixedStepClock.timestep,paused: false,rate: 1)
        try ra.advance(elapsed: 4*FixedStepClock.timestep,paused: false,rate: 1)
        for _ in 0..<4 {
            try b.advance(elapsed: FixedStepClock.timestep,paused: false,rate: 1)
            try rb.advance(elapsed: FixedStepClock.timestep,paused: false,rate: 1)
        }
    }
    #expect(a.stream.generations == b.stream.generations)
    #expect(a.tracks.map { $0.solver.state } == b.tracks.map { $0.solver.state })
    #expect(ra.stream.generations == rb.stream.generations)
    #expect(ra.tracks.map { $0.solver.position } == rb.tracks.map { $0.solver.position })
    let first = settings.beam(beam,index: 0,generation: 1)
    #expect(first != settings.beam(beam,index: 0,generation: 2))
    settings.seed += 1
    #expect(first != settings.beam(beam,index: 0,generation: 1))
    settings.variation = 0
    #expect(settings.beam(beam,index: 0,generation: 100) == beam)
    settings.variation = .nan
    #expect(throws: WormholeError.self) { try WormholeComparison(beam: beam,launches: settings) }
}

@Test func returnBlendHasContinuousGradientAndCurvature() {
    let surface = RoundedWormhole(geometry: WormholeBeam().geometry)
    for q in [0.0,0.1,0.2,0.7,1] {
        let p = surface.position(x: surface.edge-surface.width+q*surface.width,z: 2,upper: true)
        let h = 1e-5, d = surface.differential(at: p)
        for axis in 0..<3 {
            var offset = SIMD3<Double>.zero; offset[axis] = h
            let plus = surface.differential(at: p+offset), minus = surface.differential(at: p-offset)
            #expect(abs((plus.value-minus.value)/(2*h)-d.gradient[axis]) < 1e-6)
            #expect(simd_length((plus.gradient-minus.gradient)/(2*h)-d.hessian[axis]) < 1e-5)
        }
    }
}


@Test func continuousLaunchPoolPreservesParticlesThatRemainOnSurface() {
    var stream = WormholeLaunchStream(count: 13,continuous: true)
    for _ in 0..<20000 { _ = stream.advance(retired: Array(repeating: false,count: 13)) }
    #expect(stream.active.allSatisfy { $0 })
    #expect(stream.generations == Array(repeating: 1,count: 13))
}

@Test func roundedMeshStoresStableGridAnglesAtTheReturnTangent() throws {
    var geometry = WormholeBeam().geometry; geometry.funnel?.roundedReturnEdge = true
    let surface = RoundedWormhole(geometry: geometry)
    let mesh = try SurfaceMesh(ellis: geometry,columns: 256)
    var samples = 0, maximumError = 0.0
    for vertex in mesh.vertices {
        let q = (Double(vertex.position.x)-(surface.edge-surface.width))/surface.width
        if q > 0.9 {
            let expected = atan2(min(1,q),sqrt(max(0,1-q*q)))
            maximumError = max(maximumError,abs(Double(vertex.uv.z)-expected))
            samples += 1
        }
    }
    #expect(samples > 100)
    #expect(maximumError < 1e-4)
}


@Test func continuousModeStartsWithAnExactRowAndRestoresItAfterRecycling() throws {
    let beam = WormholeBeam()
    var settings = WormholeLaunchSettings(); settings.continuous = true; settings.variation = 1
    var open = try WormholeComparison(beam: beam,trailLength: 256,launches: settings)
    var rounded = try RoundedWormholeComparison(beam: beam,trailLength: 256,launches: settings)
    let originalStates = open.tracks.map { $0.solver.state }
    let originalPositions = rounded.tracks.map { $0.solver.position }
    #expect(beam.starts.indices.allSatisfy { open.isVisible($0) && rounded.isVisible($0) })
    #expect(open.stream.generations == Array(repeating: 1,count: 13))
    for i in beam.starts.indices {
        #expect(open.tracks[i].solver.state == (try WormholeSolver(configuration: beam.launch(i))).state)
        #expect(abs(rounded.tracks[i].solver.position.x-beam.starts[i].x) < 1e-12)
        #expect(abs(rounded.tracks[i].solver.position.z-beam.starts[i].y) < 1e-12)
    }
    try open.singleStep(paused: true); try rounded.step()
    #expect(open.tracks.allSatisfy { $0.solver.steps == 1 })
    #expect(rounded.tracks.allSatisfy { $0.solver.steps == 1 })
    for _ in 0..<500 {
        try open.advance(elapsed: 1.0/60,paused: false,rate: 16)
        try rounded.advance(elapsed: 1.0/60,paused: false,rate: 16)
    }
    #expect(open.stream.generations.contains { $0 > 1 })
    #expect(rounded.stream.generations.contains { $0 > 1 })
    try open.restart(paused: true)
    rounded = try RoundedWormholeComparison(beam: beam,trailLength: 256,launches: settings)
    #expect(open.tracks.map { $0.solver.state } == originalStates)
    #expect(rounded.tracks.map { $0.solver.position } == originalPositions)
    #expect(open.tracks.allSatisfy { $0.isPaused && $0.trail.count == 1 })
}

@Test func followWaitsAndReturnsWithoutLosingUserIntent() {
    var camera = OrbitCamera()
    var tracking = RelaunchCameraTracking()
    let start = SIMD3<Double>(1,2,3), relaunched = SIMD3<Double>(-18,5,0)
    tracking.setFollowing(true,camera: &camera,particle: start)
    tracking.update(particle: nil,elapsed: 1)
    #expect(tracking.isFollowing && tracking.isWaiting)
    #expect(tracking.resolved(camera: camera).target == start)
    tracking.update(particle: relaunched,elapsed: 0)
    #expect(tracking.isFollowing && tracking.isTransitioning)
    #expect(tracking.resolved(camera: camera).target == start)
    tracking.update(particle: relaunched,elapsed: 0.2)
    let middle = tracking.resolved(camera: camera).target
    #expect(middle != start && middle != relaunched)
    for _ in 0..<4 { tracking.update(particle: relaunched,elapsed: 0.2) }
    #expect(!tracking.isTransitioning && tracking.resolved(camera: camera).target == relaunched)
    tracking.setFollowing(false,camera: &camera,particle: relaunched)
    #expect(!tracking.isFollowing && camera.target == relaunched)
}

@Test func followSelectionAndReducedMotionReturnImmediately() {
    var camera = OrbitCamera(yaw: 0.7,pitch: 0.3,distance: 90)
    var tracking = RelaunchCameraTracking()
    tracking.setFollowing(true,camera: &camera,particle: nil)
    #expect(tracking.isFollowing && tracking.isWaiting)
    let p = SIMD3<Double>(5,6,7)
    tracking.update(particle: p,elapsed: 0,reduceMotion: true)
    #expect(tracking.resolved(camera: camera).target == p && !tracking.isTransitioning)
    tracking.update(particle: nil,elapsed: 0)
    let other = SIMD3<Double>(8,9,10)
    tracking.select(particle: other)
    #expect(tracking.resolved(camera: camera).target == other && !tracking.isWaiting)
    let resolved = tracking.resolved(camera: camera)
    #expect(resolved.yaw == camera.yaw && resolved.pitch == camera.pitch && resolved.distance == camera.distance)
    tracking.update(particle: nil,elapsed: 0)
    tracking.update(particle: p,elapsed: 0)
    let frozen = tracking.resolved(camera: camera)
    tracking.update(particle: p,elapsed: 0)
    #expect(tracking.resolved(camera: camera) == frozen)
    tracking.reset(camera: &camera,preset: OrbitCamera())
    #expect(!tracking.isFollowing && camera == OrbitCamera())
}
