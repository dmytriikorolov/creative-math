import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func ellisEmbeddingInducesMetricAndIsSmoothAtThroat() throws {
    for a in [1.0,2,4] {
        let geometry = EllisWormhole(throatRadius: a)
        #expect(geometry.radius(l: 0) == a)
        for l in [-12.0,-1,-1e-8,0,1e-8,1,12] {
            let phi = 0.7, h = 1e-5
            let dl = (geometry.position(l: l+h,phi: phi)-geometry.position(l: l-h,phi: phi))/(2*h)
            let dp = (geometry.position(l: l,phi: phi+h)-geometry.position(l: l,phi: phi-h))/(2*h)
            #expect(abs(dot(dl,dl)-1) < 1e-8)
            #expect(abs(dot(dp,dp)-geometry.metric(l: l).y) < 1e-7)
            #expect(abs(dot(dp,dl)) < 1e-8)
            #expect(abs(simd_length(geometry.normal(l: l,phi: phi))-1) < 1e-12)
        }
        #expect(simd_length(geometry.position(l: 1e-8,phi: 0)-geometry.position(l: -1e-8,phi: 0)) < 2.1e-8)
        let mesh = try SurfaceMesh(ellis: geometry,columns: 24,rows: 16)
        #expect(mesh.vertices.count == 25*17 && mesh.indices.count == 24*16*6)
        #expect(mesh.indices.allSatisfy { Int($0) < mesh.vertices.count })
        for row in 0...16 {
            #expect(simd_length(mesh.vertices[row*25].position-mesh.vertices[row*25+24].position) < 1e-5)
        }
        for vertex in mesh.vertices {
            #expect((0..<4).allSatisfy { vertex.position[$0].isFinite && vertex.normal[$0].isFinite })
        }
        #expect(mesh.vertices[8*25].position.y == 0) // One shared throat row, not two disconnected funnels.
        for i in stride(from: 0,to: mesh.indices.count,by: 3) {
            let a = mesh.vertices[Int(mesh.indices[i])], b = mesh.vertices[Int(mesh.indices[i+1])], c = mesh.vertices[Int(mesh.indices[i+2])]
            let x = b.position-a.position, y = c.position-a.position
            #expect(dot(cross(SIMD3(x.x,x.y,x.z),SIMD3(y.x,y.y,y.z)),SIMD3(a.normal.x,a.normal.y,a.normal.z)) > 0)
        }
    }
}

@Test func ellisAccelerationAndUnitLaunchMatchMetric() throws {
    let geometry = EllisWormhole()
    let state = SIMD4<Double>(3,0.4,-0.7,0.2)
    let d = geometry.derivative(state)
    #expect(abs(d.z-0.12) < 1e-14)
    #expect(abs(d.w-(0.84/13)) < 1e-14)
    // Differentiate the invariants algebraically, independently of integration.
    let energyDerivative = 2*state.z*d.z+2*state.x*state.z*state.w*state.w+2*geometry.metric(l: state.x).y*state.w*d.w
    let momentumDerivative = 2*state.x*state.z*state.w+geometry.metric(l: state.x).y*d.w
    #expect(abs(energyDerivative) < 1e-14 && abs(momentumDerivative) < 1e-14)
    for example in WormholeLaunch.allCases {
        let configuration = WormholeConfiguration(example: example)
        let solver = try WormholeSolver(configuration: configuration)
        #expect(abs(configuration.geometry.energy(solver.state)-1) < 1e-14)
        #expect(abs(configuration.geometry.momentum(solver.state)-configuration.angularMomentum) < 1e-14)
    }
}

@Test func ellisCrossingReturningAndNearCriticalBehavior() throws {
    for example in WormholeLaunch.allCases {
        let c = WormholeConfiguration(example: example)
        var solver = try WormholeSolver(configuration: c)
        var minimumL = c.initialL, residence = 0.0, angle = 0.0, changedSign = false
        for _ in 0..<19200 {
            let before = solver.state
            try solver.advance(steps: 1)
            minimumL = min(minimumL,solver.state.x)
            angle += abs(TorusMetric.wrap(solver.state.y-before.y))
            if abs(solver.state.x) < c.geometry.throatRadius { residence += FixedStepClock.timestep }
            if before.z < 0 && solver.state.z >= 0 { changedSign = true }
            if abs(solver.state.x) > c.geometry.extent { break }
        }
        print("ELLIS_BEHAVIOR \(example.rawValue) min_l=\(minimumL) residence_abs_l_lt_a=\(residence) angular_travel=\(angle) final_l=\(solver.state.x)")
        if example == .crossing {
            #expect(solver.state.x < -12 && !changedSign)
        } else {
            let expected = c.geometry.throatRadius*sqrt(c.impactRatio*c.impactRatio-1)
            #expect(changedSign && solver.state.x > 12 && minimumL > 0)
            #expect(abs(minimumL-expected) < 1e-5)
            if example == .nearCritical { #expect(residence > 15 && angle > 2 * .pi) }
        }
    }
}

@Test func ellisConservationOverExtendedTrajectories() throws {
    for example in WormholeLaunch.allCases {
        var c = WormholeConfiguration(example: example); c.geometry.throatRadius = 1
        var solver = try WormholeSolver(configuration: c)
        var energy = 0.0, momentum = 0.0
        for _ in 0..<240000 {
            try solver.advance(steps: 1)
            energy = max(energy,abs(solver.energyDrift)); momentum = max(momentum,abs(solver.momentumDrift))
        }
        print("ELLIS_DRIFT \(example.rawValue) a=1 duration=1000s dt=\(FixedStepClock.timestep) max_energy=\(energy) max_abs_J=\(momentum)")
        #expect(energy < 1e-7 && momentum < 1e-7)
        #expect((0..<4).allSatisfy { solver.state[$0].isFinite })
    }
}

@Test func ellisNearCriticalRK4ConvergesAndDoesNotCrossSpuriously() throws {
    let c = WormholeConfiguration(example: .nearCritical)
    func state(dt: Double) throws -> SIMD3<Double> {
        var solver = try WormholeSolver(configuration: c)
        try solver.advance(steps: Int((24/dt).rounded()),dt: dt)
        #expect(solver.state.x > 0)
        return solver.position
    }
    let reference = try state(dt: 0.0015625)
    let coarse = try simd_length(state(dt: 0.05)-reference), medium = try simd_length(state(dt: 0.025)-reference)
    let fine = try simd_length(state(dt: 0.0125)-reference)
    print("ELLIS_CONVERGENCE nearCritical t=24 errors \(coarse) \(medium) \(fine) ratios \(coarse/medium) \(medium/fine)")
    #expect(coarse/medium > 10 && coarse/medium < 24)
    #expect(medium/fine > 10 && medium/fine < 24)
}

@Test func ellisRadialGeodesicRestartAndPlaybackContinuesBeyondMesh() throws {
    var c = WormholeConfiguration(); c.impactRatio = 0
    var solver = try WormholeSolver(configuration: c), batched = solver
    try solver.advance(steps: 4800)
    for _ in 0..<200 { try batched.advance(steps: 24) }
    #expect(solver.state == batched.state)
    #expect(abs(solver.state.x-(c.initialL-20)) < 1e-10 && solver.state.y == TorusMetric.wrap(c.initialPhi))
    let expected = solver.state; solver.restart(); try solver.advance(steps: 4800)
    #expect(solver.state == expected)
    var playback = try WormholePlayback(configuration: c,trailLength: 256)
    playback.playbackRate = 4
    for _ in 0..<1000 { try playback.advance(elapsed: 1.0/60) }
    #expect(playback.hasExited && !playback.isPaused && playback.trail.count == 256)
    #expect(playback.solver.steps == 16000 && playback.solver.state.x < -50)
    playback.isPaused = true
    let frozen = playback.solver.state
    try playback.advance(elapsed: 1)
    #expect(playback.solver.state == frozen)
    try playback.singleStep()
    #expect(playback.solver.steps == 16001)
    playback.restart()
    #expect(!playback.hasExited && playback.isPaused && playback.playbackRate == 4 && playback.trail.count == 1)
    try playback.singleStep(); #expect(playback.solver.steps == 1)
}

@Test func ellisDisplayInterpolationAndFollowStayContinuousAcrossThroatAndSeam() throws {
    var c = WormholeConfiguration(); c.initialL = 0.01; c.initialPhi = .pi-0.0001
    var playback = try WormholePlayback(configuration: c)
    playback.playbackRate = 1
    var camera = c.geometry.camera, tracking = ParticleCameraTracking()
    tracking.setFollowing(true,camera: &camera,particle: playback.presentationPosition)
    var previous = playback.presentationPosition
    for _ in 0..<120 {
        try playback.advance(elapsed: 1.0/480)
        let p = playback.presentationPosition
        #expect(simd_length(p-previous) < 0.003)
        let resolved = tracking.resolved(camera: camera,particle: p)
        #expect(resolved.target == p && resolved.yaw == camera.yaw && resolved.pitch == camera.pitch)
        // Invert the embedding height to verify presentation also lies on the geometry.
        let l = c.geometry.throatRadius*sinh(p.y/c.geometry.throatRadius)
        #expect(abs(hypot(p.x,p.z)-c.geometry.radius(l: l)) < 1e-12)
        previous = p
    }
    #expect(playback.solver.state.x < 0 && playback.solver.state.y < 0)
    playback.isPaused = true
    let fixed = playback.presentationPosition
    try playback.advance(elapsed: 100)
    #expect(playback.presentationPosition == fixed)
}

@Test func ellisInputsValidateWithoutClampingLaunches() throws {
    for a in [0.0,-1,Double.nan,.infinity,5] {
        var c = WormholeConfiguration(); c.geometry.throatRadius = a
        #expect(!c.isValid)
        #expect(throws: WormholeError.self) { try WormholeSolver(configuration: c) }
    }
    var c = WormholeConfiguration(); c.initialL = 0; c.impactRatio = 1.1
    #expect(!c.isValid)
    c.impactRatio = 1 // The exact critical throat circle is valid, but not the near-critical preset.
    var circle = try WormholeSolver(configuration: c)
    try circle.advance(steps: 2400)
    #expect(circle.state.x == 0 && circle.state.z == 0)
    c.initialL = .nan; #expect(!c.isValid)
    c = WormholeConfiguration(); c.impactRatio = .infinity; #expect(!c.isValid)
    #expect(throws: SurfaceError.self) { try SurfaceMesh(ellis: EllisWormhole(),rows: 15) }
    #expect(throws: GeodesicError.self) { try WormholePlayback(configuration: WormholeConfiguration(),trailLength: Int.max) }
}

@Test func ellisSignedRegionAndWindingSymmetries() throws {
    let positive = WormholeConfiguration(example: .deflection)
    var negative = positive, reverse = positive
    negative.initialL = -positive.initialL; reverse.impactRatio = -positive.impactRatio
    var a = try WormholeSolver(configuration: positive), b = try WormholeSolver(configuration: negative), c = try WormholeSolver(configuration: reverse)
    for _ in 0..<7200 {
        try a.advance(steps: 1); try b.advance(steps: 1); try c.advance(steps: 1)
        #expect(abs(a.state.x+b.state.x) < 1e-12 && abs(a.state.z+b.state.z) < 1e-12)
        #expect(abs(a.state.x-c.state.x) < 1e-12)
        #expect(abs(TorusMetric.wrap(a.state.y+c.state.y-2*positive.initialPhi)) < 1e-10)
    }
}
