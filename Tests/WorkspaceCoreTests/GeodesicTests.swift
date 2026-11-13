import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func torusMetricAndAccelerationMatchGeometry() {
    let torus = TorusMetric()
    for u in [0.1,1.0,3.0] { for v in [-2.0,0.0,1.3] {
        let h = 1e-5
        let du = (torus.position(u: u+h,v: v)-torus.position(u: u-h,v: v))/(2*h)
        let dv = (torus.position(u: u,v: v+h)-torus.position(u: u,v: v-h))/(2*h)
        let g = torus.metric(v: v)
        #expect(abs(dot(du,du)-g.x) < 3e-9)
        #expect(abs(dot(dv,dv)-g.y) < 3e-9 && abs(dot(du,dv)) < 1e-9)
        var parameters = SurfacePreset.torus.parameters
        parameters.majorRadius = torus.majorRadius; parameters.tubeRadius = torus.minorRadius
        #expect(simd_length(torus.displayPosition(u: u,v: v)-parameters.sample(u: u/(2 * .pi),v: v/(2 * .pi)).position) < 1e-12)
        // Euler–Lagrange: d(g_uu*u')/dt = 0 and r²*v'' = -A*r*sin(v)*u'².
        let state = SIMD4(u,v,0.3,-0.7), d = torus.derivative(SIMD4(u,v,0.3,-0.7))
        let a = torus.majorRadius+torus.minorRadius*cos(v)
        #expect(abs(g.x*d.z-2*a*torus.minorRadius*sin(v)*state.w*state.z) < 1e-12)
        #expect(abs(g.y*d.w+a*torus.minorRadius*sin(v)*state.z*state.z) < 1e-12)
    } }
}

@Test func launchIsNormalizedInTheMetricAtEveryPosition() throws {
    for v in [0.0,0.5,Double.pi,2 * .pi] { for angle in [-Double.pi,-1,0,1,Double.pi] {
        var c = TorusGeodesicConfiguration(); c.initialV = v; c.direction = angle
        let solver = try TorusGeodesicSolver(configuration: c)
        #expect(abs(c.torus.speedSquared(solver.state)-c.speed*c.speed) < 1e-12)
    } }
}

@Test func periodicWrappingAndSeamsRemainGeometricallyContinuous() throws {
    let m = TorusMetric()
    for angle in [-100.0,-2 * .pi,-Double.pi,0,.pi,2 * .pi,100] {
        let wrapped = TorusMetric.wrap(angle)
        #expect(wrapped >= -.pi && wrapped < .pi)
        #expect(simd_length(m.position(u: angle,v: angle)-m.position(u: wrapped,v: wrapped)) < 1e-12)
    }
    #expect(TorusMetric.wrap(.infinity).isNaN)
    var c = TorusGeodesicConfiguration(); c.initialU = .pi-0.001; c.initialV = .pi-0.001
    var solver = try TorusGeodesicSolver(configuration: c)
    for _ in 0..<4000 {
        let before = solver.position
        try solver.advance(steps: 1)
        #expect(simd_length(solver.position-before) <= c.speed*TorusGeodesicConfiguration.timestep*1.00001)
        #expect(abs(solver.state.x) <= .pi && abs(solver.state.y) <= .pi)
    }
}

@Test func equatorialGeodesicsTraceActualCirclesOverMultipleLaps() throws {
    for v in [0.0,Double.pi] {
        var c = TorusGeodesicConfiguration(); c.initialU = 0; c.initialV = v; c.direction = 0
        var solver = try TorusGeodesicSolver(configuration: c)
        let radius = c.torus.majorRadius+c.torus.minorRadius*cos(v)
        var maxError = 0.0
        for i in 1...24000 {
            try solver.advance(steps: 1)
            let angle = c.speed/radius*Double(i)*TorusGeodesicConfiguration.timestep
            let expected = SIMD3(radius*cos(angle),0,radius*sin(angle))
            maxError = max(maxError,simd_length(solver.position-expected))
            #expect(abs(solver.state.w) < 1e-15)
        }
        print("GEODESIC_EQUATOR v=\(v) time=100s maximum world error=\(maxError)")
        #expect(maxError < 1e-9)
    }
}

@Test func integrationRestartBatchingAndRingHistoryAreDeterministic() throws {
    let c = TorusGeodesicConfiguration()
    var a = try TorusGeodesicSolver(configuration: c), b = a
    try a.advance(steps: 2400)
    for _ in 0..<100 { try b.advance(steps: 24) }
    #expect(a.state == b.state)
    let expected = a.state; a.restart(); try a.advance(steps: 2400)
    #expect(a.state == expected)
    var playback = try GeodesicPlayback(configuration: c,trailLength: 256)
    for _ in 0..<100 { try playback.advance(elapsed: 1.0/60) }
    #expect(playback.solver.steps == 400 && playback.trail.count == 256 && playback.trail.head == 144)
    let last = try #require(playback.trail.point(oldestIndex: 255))
    #expect(SIMD3(last.x,last.y,last.z) == SIMD3<Float>(playback.solver.position))
    playback.isPaused = true
    let paused = playback.solver.state
    try playback.advance(elapsed: 100)
    #expect(playback.solver.state == paused && playback.clock.discardedTime == 0)
    try playback.singleStep()
    #expect(playback.solver.steps == 401 && playback.trail.head == 145)
    playback.restart()
    #expect(playback.isPaused && playback.solver.steps == 0 && playback.trail.count == 1 && playback.trail.head == 0)
    #expect(playback.solver.state == c.initialState)
    #expect(playback.trail.point(oldestIndex: 1) == nil)
}

@Test func geodesicClockIsIndependentOfDisplayRefresh() throws {
    var expected: SIMD4<Double>?
    for hz in [30,60,120,144] {
        var playback = try GeodesicPlayback(configuration: TorusGeodesicConfiguration())
        for _ in 0..<(hz*10) { try playback.advance(elapsed: 1/Double(hz)) }
        #expect(playback.solver.steps == 2400)
        if let expected { #expect(playback.solver.state == expected) } else { expected = playback.solver.state }
        let state = playback.solver.state
        try playback.singleStep() // Running single-step is intentionally inert.
        #expect(playback.solver.state == state)
    }
}

@Test func extendedGeodesicsStayFiniteOnSurfaceWithMeasuredDrift() throws {
    var difficult = TorusGeodesicConfiguration()
    difficult.torus = TorusMetric(majorRadius: 4,minorRadius: 3); difficult.speed = 8
    for configuration in [TorusGeodesicConfiguration(),difficult] {
        var solver = try TorusGeodesicSolver(configuration: configuration)
        let momentum = configuration.torus.angularMomentum(solver.state)
        var maxSpeed = 0.0, maxMomentum = 0.0, maxConstraint = 0.0
        for _ in 0..<240000 {
            try solver.advance(steps: 1)
            maxSpeed = max(maxSpeed,abs(solver.relativeSpeedDrift))
            maxMomentum = max(maxMomentum,abs(configuration.torus.angularMomentum(solver.state)/momentum-1))
            let p = solver.position, radius = hypot(p.x,p.z)-configuration.torus.majorRadius
            maxConstraint = max(maxConstraint,abs(radius*radius+p.y*p.y-configuration.torus.minorRadius*configuration.torus.minorRadius))
        }
        print("GEODESIC_DRIFT R=\(configuration.torus.majorRadius) r=\(configuration.torus.minorRadius) speed=\(configuration.speed) duration=1000s dt=\(TorusGeodesicConfiguration.timestep) max relative speed=\(maxSpeed) momentum=\(maxMomentum) constraint=\(maxConstraint)")
        #expect(maxSpeed < 1e-7 && maxMomentum < 1e-7)
        #expect(maxConstraint < 1e-11)
    }
}

@Test func rk4GeodesicsConvergeWhenTimestepIsHalved() throws {
    let c = TorusGeodesicConfiguration()
    func result(dt: Double) throws -> SIMD3<Double> {
        var solver = try TorusGeodesicSolver(configuration: c)
        try solver.advance(steps: Int((12/dt).rounded()),dt: dt); return solver.position
    }
    let reference = try result(dt: 0.003125)
    let coarse = try simd_length(result(dt: 0.1)-reference)
    let medium = try simd_length(result(dt: 0.05)-reference)
    let fine = try simd_length(result(dt: 0.025)-reference)
    print("GEODESIC_CONVERGENCE time=12s errors h=.1,.05,.025: \(coarse), \(medium), \(fine); ratios \(coarse/medium), \(medium/fine)")
    #expect(coarse/medium > 10 && coarse/medium < 24)
    #expect(medium/fine > 10 && medium/fine < 24)
}

@Test func invalidGeodesicInputsAreRejected() throws {
    for value in [Double.nan,.infinity,-.infinity] {
        var c = TorusGeodesicConfiguration(); c.speed = value
        #expect(throws: GeodesicError.self) { try TorusGeodesicSolver(configuration: c) }
        c = TorusGeodesicConfiguration(); c.initialU = value
        #expect(!c.isValid)
        c = TorusGeodesicConfiguration(); c.torus.minorRadius = value
        #expect(!c.isValid)
    }
    for metric in [TorusMetric(majorRadius: 2,minorRadius: 2),TorusMetric(minorRadius: 0),TorusMetric(majorRadius: 0)] {
        #expect(!metric.isValid)
    }
    var solver = try TorusGeodesicSolver(configuration: TorusGeodesicConfiguration())
    #expect(throws: GeodesicError.self) { try solver.advance(steps: 1,dt: .nan) }
    #expect(throws: GeodesicError.self) { try solver.advance(steps: -1) }
    #expect(throws: GeodesicError.self) { try GeodesicTrail(capacity: Int.max) }
}


@Test func nearbyInnerEquatorIsNotArtificiallyLockedAndFloatTrailStaysOnSurface() throws {
    var c = TorusGeodesicConfiguration(); c.initialV = .pi-0.0001; c.direction = 0
    var solver = try TorusGeodesicSolver(configuration: c)
    try solver.advance(steps: 2400)
    #expect(abs(TorusMetric.wrap(solver.state.y-c.initialV)) > 0.001)
    var playback = try GeodesicPlayback(configuration: TorusGeodesicConfiguration(),trailLength: 256)
    for _ in 0..<120 { try playback.advance(elapsed: 1.0/60) }
    for i in 0..<playback.trail.count {
        let point = try #require(playback.trail.point(oldestIndex: i))
        let radial = hypot(Double(point.x),Double(point.z))-6
        #expect(abs(radial*radial+Double(point.y)*Double(point.y)-4) < 5e-6)
    }
}

@Test func meridiansAndSupportedRadiusCornersStayFinite() throws {
    var c = TorusGeodesicConfiguration(); c.initialU = 0; c.initialV = 0; c.direction = .pi/2
    var solver = try TorusGeodesicSolver(configuration: c)
    for i in 1...7200 {
        try solver.advance(steps: 1)
        let v = c.speed/c.torus.minorRadius*Double(i)*TorusGeodesicConfiguration.timestep
        #expect(simd_length(solver.position-SIMD3(6+2*cos(v),2*sin(v),0)) < 1e-9)
    }
    for major in [4.0,9] { for minor in [0.5,3] { for v in [0.0,Double.pi] { for angle in [0.0,Double.pi/2,1.1] {
        c.torus = TorusMetric(majorRadius: major,minorRadius: minor); c.initialV = v; c.direction = angle; c.speed = 8
        var corner = try TorusGeodesicSolver(configuration: c)
        try corner.advance(steps: 7200)
        #expect(abs(corner.relativeSpeedDrift) < 1e-7)
        #expect((0..<4).allSatisfy { corner.state[$0].isFinite })
    } } } }
}

@Test func geodesicPauseFreezesTrailAgeAndStepAgesExactlyOnce() throws {
    var playback = try GeodesicPlayback(configuration: TorusGeodesicConfiguration())
    try playback.advance(elapsed: 0.1)
    playback.isPaused = true
    let head = playback.trail.head, count = playback.trail.count
    let oldest = playback.trail.point(oldestIndex: 0)
    let fade = TrailFade(delay: 0,duration: 1)
    let age = TrailFade.sampleAge(index: 0,count: count)
    try playback.advance(elapsed: 3600)
    #expect(playback.trail.head == head && playback.trail.count == count)
    #expect(fade.opacity(age: TrailFade.sampleAge(index: 0,count: playback.trail.count)) == fade.opacity(age: age))
    try playback.singleStep()
    #expect(playback.trail.point(oldestIndex: 0) == oldest)
    #expect(abs(TrailFade.sampleAge(index: 0,count: playback.trail.count)-age-TorusGeodesicConfiguration.timestep) < 1e-15)
}

@Test func playbackMultiplierChangesRateWithoutRestartOrLargerSteps() throws {
    let configuration = TorusGeodesicConfiguration()
    var normal = try GeodesicPlayback(configuration: configuration)
    var fast = try GeodesicPlayback(configuration: configuration)
    fast.playbackRate = 4
    for _ in 0..<600 { try normal.advance(elapsed: 1.0/60) }
    for _ in 0..<150 { try fast.advance(elapsed: 1.0/60) }
    #expect(fast.solver.steps == 2400 && fast.solver.state == normal.solver.state)
    fast.isPaused = true
    let before = fast.solver.steps
    try fast.advance(elapsed: 100)
    #expect(fast.solver.steps == before)
    try fast.singleStep()
    #expect(fast.solver.steps == before+1)
    fast.restart()
    #expect(fast.playbackRate == 4 && fast.isPaused && fast.solver.steps == 0)
    fast.playbackRate = .nan
    #expect(throws: GeodesicError.self) { try fast.advance(elapsed: 1) }
}

@Test func particleAndTrailAppearanceValidateScreenPointRanges() {
    var appearance = GeodesicAppearance()
    #expect(appearance.isValid && appearance.particleDiameterPoints == 12)
    appearance.particleDiameterPoints = .nan
    #expect(!appearance.isValid)
    appearance.particleDiameterPoints = 28
    appearance.trailWidthPoints = 3
    #expect(appearance.isValid)
    appearance.trailWidthPoints = .infinity
    #expect(!appearance.isValid)
}
