import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func oscillatorIntegratorsShowExpectedConvergenceOrder() throws {
    func error(_ method: PlanarIntegrator,_ dt: Double) throws -> Double {
        var settings = VectorIntegrationSettings(); settings.method = method; settings.timestep = dt
        var run = try VectorTrajectory(field: PlanarVectorField(),start: SIMD2(1,0),settings: settings)
        for _ in 0..<Int((1/dt).rounded()) { run.step() }
        return simd_length(run.current.point-SIMD2(cos(1),-sin(1)))
    }
    let coarse = try error(.rk4,0.05), fine = try error(.rk4,0.025)
    #expect(coarse/fine > 14 && coarse/fine < 18)
    let eulerCoarse = try error(.euler,0.05), eulerFine = try error(.euler,0.025)
    #expect(eulerCoarse/eulerFine > 1.8 && eulerCoarse/eulerFine < 2.2)
}

@Test func linearFieldsMatchAnalyticSolutionsAndEquilibria() throws {
    for preset in [VectorFieldPreset.spiral,.saddle] {
        let parameter = preset.defaultParameter, field = PlanarVectorField(preset: preset,parameter: parameter)
        var run = try VectorTrajectory(field: field,start: SIMD2(1,0.5))
        for _ in 0..<240 { run.step() }
        let t = run.current.time
        let expected = preset == .saddle ? SIMD2(exp(t),0.5*exp(-t)) : exp(-parameter*t)*SIMD2(cos(t)-0.5*sin(t),sin(t)+0.5*cos(t))
        #expect(simd_length(run.current.point-expected) < 1e-8)
        var equilibrium = try VectorTrajectory(field: field,start: .zero)
        equilibrium.step(); #expect(equilibrium.status == .equilibrium && equilibrium.steps == 0)
    }
}

@Test func variableFixedStepClockKeepsCadencePauseAndCatchUpBound() throws {
    var settings = VectorIntegrationSettings(); settings.timestep = 0.01
    var a = try VectorTrajectory(field: PlanarVectorField(preset: .vanDerPol),start: SIMD2(2,0),settings: settings)
    var b = a
    for _ in 0..<600 {
        a.advance(elapsed: 1.0/60)
        b.advance(elapsed: 1.0/120); b.advance(elapsed: 1.0/120)
    }
    #expect(a.steps == 1000 && a.current.point == b.current.point)
    let before = a.current
    a.advance(elapsed: 100,paused: true)
    #expect(a.current.point == before.point && a.current.time == before.time)
    a.step(); #expect(abs(a.current.time-before.time-settings.timestep) < 1e-12)
    var clock = FixedStepClock()
    #expect(clock.consume(elapsed: 10,timestep: 0.001) == 64)
    #expect(clock.discardedTime > 9.9)
    #expect(clock.consume(elapsed: 0.01,timestep: .nan) == 0)
}

@Test func nonlinearFieldRemainsFiniteAndSafetyStopsRetainValidState() throws {
    for parameter in [0.0,1,4] {
        var run = try VectorTrajectory(field: PlanarVectorField(preset: .vanDerPol,parameter: parameter),start: SIMD2(2,0))
        for _ in 0..<10000 { run.step() }
        #expect(run.status == .stepLimit && run.history.count == 10001)
        #expect(run.history.allSatisfy { simd_length($0.point) < 10 })
    }
    struct Explosive: VectorField2D {
        func vector(at p: SIMD2<Double>) -> SIMD2<Double> { SIMD2(1e300,1e300) }
    }
    var unsafe = try VectorTrajectory(field: Explosive(),start: SIMD2(1,1))
    unsafe.step()
    #expect(unsafe.status == .numericalLimit && unsafe.history.count == 1 && unsafe.current.point == SIMD2(1,1))
    var invalid = VectorIntegrationSettings(); invalid.timestep = .infinity
    #expect(throws: VectorIntegrationError.self) { try VectorTrajectory(field: PlanarVectorField(),start: .zero,settings: invalid) }
    #expect(throws: VectorIntegrationError.self) { try VectorTrajectory(field: PlanarVectorField(),start: SIMD2(.nan,0)) }
}
