import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func fadeDelayDurationAndSmoothBoundaries() {
    let fade = TrailFade(delay: 2, duration: 4)
    #expect(fade.opacity(age: -1) == 1)
    #expect(fade.opacity(age: 2) == 1)
    #expect(fade.opacity(age: 4) == 0.5)
    #expect(fade.opacity(age: 6) == 0)
    #expect(fade.opacity(age: 100) == 0)
    #expect(abs(fade.opacity(age: 2+1e-6)-1) < 1e-10)
    #expect(fade.opacity(age: 6-1e-6) < 1e-10)
    var previous = 1.0
    for i in 0...1000 {
        let value = fade.opacity(age: Double(i)/100)
        #expect((0...1).contains(value) && value <= previous)
        previous = value
    }
}

@Test func fadeZeroDurationInvalidInputsAndHistoryLimits() {
    let instant = TrailFade(delay: 1, duration: 0)
    #expect(instant.opacity(age: 1) == 1 && instant.opacity(age: 1.000001) == 0)
    #expect(instant.opacity(age: .nan) == 0)
    #expect(!TrailFade(delay: -1).isValid)
    #expect(!TrailFade(duration: .infinity).isValid)
    #expect(TrailFade(delay: 30, duration: 30).opacity(age: 8, historyDuration: 8) == 0)
    #expect(TrailFade(delay: 30, duration: 30).opacity(age: 7.875, historyDuration: 8) == 0.5)
    #expect(instant.opacity(age: 0, historyDuration: 0) == 0)
    #expect(TrailFade(delay: 30, duration: 30).visibleSegments(historyLength: 256) == 255)
    #expect(TrailFade(delay: 0, duration: 0).visibleSegments(historyLength: 2048) == 1)
}

@Test func pauseFreezesSimulationAgeAndSingleStepAdvancesIt() {
    var clock = FixedStepClock()
    let fade = TrailFade(delay: 0, duration: 1)
    var count = 101
    let age = TrailFade.sampleAge(index: 0, count: count)
    let alpha = fade.opacity(age: age)
    for _ in 0..<120 { count += clock.consume(elapsed: 1, paused: true) }
    #expect(TrailFade.sampleAge(index: 0, count: count) == age)
    #expect(fade.opacity(age: TrailFade.sampleAge(index: 0, count: count)) == alpha)
    count += clock.consume(elapsed: LorenzConfiguration.timestep)
    #expect(abs(TrailFade.sampleAge(index: 0, count: count)-age-LorenzConfiguration.timestep) < 1e-12)
    #expect(fade.opacity(age: TrailFade.sampleAge(index: 0, count: count)) < alpha)
}

@Test func transportedRibbonFramesHandlePolesReversalsAndInvalidTangents() {
    let tangents: [SIMD3<Double>] = [SIMD3(1,0,0), SIMD3(0,1,0), SIMD3(0,0,1),
        SIMD3(0,0,-1), .zero, SIMD3(.nan,0,0), SIMD3(1e-20,0,0), SIMD3(-1,0,0)]
    var previousTangent = SIMD3<Double>(1,0,0)
    var side = RibbonGeometry.initialSide(tangent: previousTangent)
    for tangent in tangents {
        let next = RibbonGeometry.transport(side: side, from: previousTangent, to: tangent)
        let t = RibbonGeometry.unit(tangent, fallback: RibbonGeometry.unit(previousTangent, fallback: SIMD3(1,0,0)))
        #expect(abs(simd_length(next)-1) < 1e-12)
        #expect(abs(dot(next,t)) < 1e-12)
        #expect(dot(side,next) >= -1e-12)
        previousTangent = t; side = next
    }
}

@Test func packedRibbonFramesAreFiniteAndKeepPrecision() {
    for x in -5...5 { for y in -5...5 { for z in -5...5 {
        let original = RibbonGeometry.unit(SIMD3(Double(x),Double(y),Double(z)), fallback: SIMD3(0,1,0))
        let packed = RibbonGeometry.pack(original)
        #expect(packed < 1<<24)
        #expect(UInt32(Float(packed)) == packed)
        #expect(dot(original, RibbonGeometry.unpack(packed)) > 0.99999)
    } } }
}

@Test func presetRepresentationsAndAppearanceLimits() {
    #expect(LorenzPreset.classic.appearance.representation == .line)
    #expect(LorenzPreset.filament.appearance.representation == .line)
    #expect(LorenzPreset.sculpture.appearance.representation == .ribbon)
    for preset in LorenzPreset.allCases { #expect(preset.appearance.isValid) }
    var appearance = LorenzPreset.sculpture.appearance
    appearance.ribbonWidth = .nan
    #expect(!appearance.isValid)
}

@Test func packedTransportStaysStableAlongLorenzTrajectory() {
    var point = SIMD3<Double>(1,1,1)
    let parameters = LorenzParameters()
    func tangent(_ p: SIMD3<Double>) -> SIMD3<Double> {
        let v = LorenzMath.derivative(p, parameters: parameters)
        return SIMD3(v.x,v.z,-v.y)
    }
    var oldTangent = tangent(point)
    var side = RibbonGeometry.initialSide(tangent: oldTangent)
    for _ in 0..<3000 {
        point = LorenzMath.rk4(point, parameters: parameters)
        let newTangent = tangent(point)
        let next = RibbonGeometry.unpack(RibbonGeometry.pack(RibbonGeometry.transport(side: side, from: oldTangent, to: newTangent)))
        #expect(abs(dot(next, RibbonGeometry.unit(newTangent, fallback: SIMD3(1,0,0)))) < 0.002)
        #expect(dot(next,side) > -0.002)
        #expect(abs(simd_length(next)-1) < 1e-12)
        oldTangent = newTangent; side = next
    }
}

@Test func fadeDrawRangeNeverOmitsANonzeroEndpoint() {
    for delay in [0.0, 1.0/240, 0.1, 30] {
        for duration in [0.0, 1.0/240, 0.17, 30] {
            let fade = TrailFade(delay: delay, duration: duration)
            for length in [256, 2048, 8192] {
                let visible = fade.visibleSegments(historyLength: length)
                #expect((1..<length).contains(visible))
                // Oldest endpoint of the first omitted segment has age > visible*dt;
                // even its newer endpoint must already have zero opacity.
                if visible < length-1 {
                    #expect(fade.opacity(age: Double(visible)*LorenzConfiguration.timestep) == 0)
                }
                #expect(fade.opacity(age: 0, historyDuration: Double(length-1)*LorenzConfiguration.timestep) == 1)
            }
        }
    }
}
