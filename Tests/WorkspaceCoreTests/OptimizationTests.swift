import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func objectiveDerivativesMatchIndependentCentralDifferences() {
    for objective in ObjectivePreset.allCases {
        for point in [SIMD2(-1.2,0.7),SIMD2(0.3,-0.6),SIMD2(1,1)] {
            let s = objective.sample(at: point), h = 1e-5
            #expect(s.isFinite)
            for axis in 0..<2 {
                var delta = SIMD2<Double>.zero; delta[axis] = h
                let a = objective.sample(at: point-delta), b = objective.sample(at: point+delta)
                #expect(abs((b.value-a.value)/(2*h)-s.gradient[axis]) < 1e-5)
                #expect(simd_length((b.gradient-a.gradient)/(2*h)-s.hessian[axis]) < 1e-5)
            }
        }
    }
}

@Test func optimizationMethodsConvergeOnQuadraticAndRepeatExactly() throws {
    for method in OptimizationMethod.allCases {
        var settings = OptimizationSettings(); settings.method = method; settings.stepSize = method == .newton ? 1 : 0.1
        var run = try OptimizationRun(objective: ObjectivePreset.quadratic,start: SIMD2(2,-2),settings: settings)
        var repeated = run
        while run.canStep { run.step(); repeated.step() }
        #expect(run.status == .converged)
        #expect(run.current.gradientNorm <= settings.tolerance && simd_length(run.current.point) < 2e-6)
        #expect(run.records.map(\.point) == repeated.records.map(\.point))
        #expect(zip(run.records,run.records.dropFirst()).allSatisfy { $1.value <= $0.value })
        if method == .newton { #expect(run.current.iteration == 1) }
    }
}

@Test func safeguardedNewtonHandlesNonconvexAndIllConditionedObjectives() throws {
    var settings = OptimizationSettings(); settings.method = .newton; settings.stepSize = 1
    for objective in [ObjectivePreset.rosenbrock,.doubleWell,.illConditioned] {
        var run = try OptimizationRun(objective: objective,start: objective.start,settings: settings)
        while run.canStep { run.step() }
        #expect(run.status == .converged)
        #expect(abs(run.current.value) < 1e-10)
        #expect(run.current.iteration < 200)
    }
    // Start where the double-well Hessian is indefinite: regularization must occur.
    var indefinite = try OptimizationRun(objective: ObjectivePreset.doubleWell,start: SIMD2(0.1,1),settings: settings)
    indefinite.step()
    #expect(indefinite.current.hessianShift > 0 && indefinite.current.value < indefinite.records[0].value)
}

@Test func safeguardsDoNotCallASaddleAMinimumAndLimitsStayBounded() throws {
    var saddle = try OptimizationRun(objective: ObjectivePreset.saddle,start: .zero)
    saddle.step(); #expect(saddle.status == .nonminimum && saddle.current.iteration == 0)
    var settings = OptimizationSettings(); settings.maximumIterations = 3; settings.stepSize = 2
    var run = try OptimizationRun(objective: ObjectivePreset.illConditioned,start: SIMD2(2,2),settings: settings)
    while run.canStep { run.step() }
    #expect(run.status == .iterationLimit && run.records.count == 4)
    #expect(run.records[1].stepSize < settings.stepSize) // actual Armijo reduction
    let frozen = run.current.point
    run.step(); #expect(run.current.point == frozen && run.records.count == 4)
    for value in [Double.nan,.infinity,-1,0] {
        settings.stepSize = value
        #expect(throws: OptimizationError.self) { try OptimizationRun(objective: ObjectivePreset.quadratic,start: .zero,settings: settings) }
    }
    #expect(throws: OptimizationError.self) { try OptimizationRun(objective: ObjectivePreset.quadratic,start: SIMD2(.nan,0)) }
}

@Test func sampledContoursUseTheObjectiveAndRejectInvalidDomains() throws {
    let objective = ObjectivePreset.quadratic
    let grid = try ObjectiveGrid(objective: objective,domain: objective.domain)
    #expect(!grid.contours.isEmpty && grid.values.count == 65*65 && grid.levels.count == 12)
    for segment in grid.contours {
        #expect(grid.domain.contains(segment.a) && grid.domain.contains(segment.b))
        #expect(abs(objective.sample(at: segment.a).value-segment.level) < 0.006)
        #expect(abs(objective.sample(at: segment.b).value-segment.level) < 0.006)
    }
    #expect(throws: OptimizationError.self) { try ObjectiveGrid(objective: objective,domain: PlanarDomain(minimum: .zero,maximum: .zero)) }
    #expect(throws: OptimizationError.self) { try ObjectiveGrid(objective: objective,domain: objective.domain,resolution: Int.max) }
}
