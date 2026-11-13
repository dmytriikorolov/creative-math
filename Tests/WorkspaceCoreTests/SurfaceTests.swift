import Foundation
import simd
import Testing
@testable import WorkspaceCore

@Test func torusSamplesSatisfyImplicitSurfaceAndPeriodicSeams() {
    let parameters = SurfacePreset.torus.parameters
    for i in 0...20 { for j in 0...20 {
        let u = Double(i)/20, v = Double(j)/20
        let sample = parameters.sample(u: u, v: v), p = sample.position
        let radial = hypot(p.x,p.z)-parameters.majorRadius
        #expect(abs(radial*radial+p.y*p.y-parameters.tubeRadius*parameters.tubeRadius) < 1e-12)
        #expect(abs(simd_length(sample.normal)-1) < 1e-12)
        #expect(simd_length(parameters.sample(u: 0,v: v).position-parameters.sample(u: 1,v: v).position) < 1e-12)
        #expect(simd_length(parameters.sample(u: u,v: 0).position-parameters.sample(u: u,v: 1).position) < 1e-12)
    } }
}

@Test func wormholeHasOpenThroatFixedRimAndContinuousFlatLimit() {
    var parameters = SurfacePreset.wormhole.parameters
    for depth in [0.0, 0.0001, 7, 12] {
        parameters.depth = depth
        for u in [0.0, 0.25, 0.5, 0.75, 1] {
            let throat = parameters.sample(u: u,v: 0), rim = parameters.sample(u: u,v: 1)
            #expect(abs(hypot(throat.position.x,throat.position.z)-parameters.throat) < 1e-12)
            #expect(throat.position.y == -depth && rim.position.y == 0)
            #expect(abs(hypot(rim.position.x,rim.position.z)-parameters.radius) < 1e-12)
            for v in [0.0, 0.1, 0.5, 1] {
                let sample = parameters.sample(u: u,v: v)
                #expect(abs(simd_length(sample.normal)-1) < 1e-12)
                #expect(sample.normal.y >= 0)
                if depth == 0 { #expect(sample.position.y == 0 && sample.normal == SIMD3(0,1,0)) }
            }
        }
    }
}

@Test func analyticSurfaceNormalsAreOrthogonalToFiniteDifferenceTangents() {
    let h = 1e-5
    for preset in SurfacePreset.allCases {
        let parameters = preset.parameters
        for u in [0.1,0.35,0.7] { for v in [0.1,0.5,0.9] {
            let sample = parameters.sample(u: u,v: v)
            let du = parameters.sample(u: u+h,v: v).position-parameters.sample(u: u-h,v: v).position
            let dv = parameters.sample(u: u,v: v+h).position-parameters.sample(u: u,v: v-h).position
            #expect(abs(dot(normalize(du),sample.normal)) < 1e-8)
            #expect(abs(dot(normalize(dv),sample.normal)) < 1e-8)
        } }
    }
}

@Test func meshBoundsSeamsAndParameterValidation() throws {
    #expect(MemoryLayout<SurfaceVertex>.stride == 48)
    for preset in SurfacePreset.allCases {
        let mesh = try SurfaceMesh(parameters: preset.parameters,columns: 24,rows: 12)
        #expect(mesh.vertices.count == 25*13 && mesh.indices.count == 24*12*6)
        #expect(mesh.indices.allSatisfy { Int($0) < mesh.vertices.count })
        for vertex in mesh.vertices {
            #expect((0..<4).allSatisfy { vertex.position[$0].isFinite && vertex.normal[$0].isFinite })
        }
        for triangle in stride(from: 0,to: mesh.indices.count,by: 3) {
            let a = mesh.vertices[Int(mesh.indices[triangle])]
            let b = mesh.vertices[Int(mesh.indices[triangle+1])]
            let c = mesh.vertices[Int(mesh.indices[triangle+2])]
            let ab = b.position-a.position, ac = c.position-a.position
            let face = cross(SIMD3(ab.x,ab.y,ab.z),SIMD3(ac.x,ac.y,ac.z))
            #expect(dot(face,SIMD3(a.normal.x,a.normal.y,a.normal.z)) > 0)
        }
        for row in 0...12 {
            let first = mesh.vertices[row*25], last = mesh.vertices[row*25+24]
            #expect(simd_length(first.position-last.position) < 1e-5)
            #expect(first.uv.x == 0 && last.uv.x == 1)
        }
    }
    var invalid = SurfaceParameters()
    invalid.throat = .nan
    #expect(throws: SurfaceError.self) { try SurfaceMesh(parameters: invalid) }
    invalid = SurfaceParameters(); invalid.depth = .infinity
    #expect(!invalid.isValid)
    invalid = SurfaceParameters(); invalid.tubeRadius = 4
    #expect(!invalid.isValid)
    #expect(throws: SurfaceError.self) { try SurfaceMesh(parameters: SurfaceParameters(), columns: Int.max) }
    for throat in [0.5,4.0] { for radius in [6.0,14.0] { for depth in [0.0,12.0] {
        var parameters = SurfaceParameters(); parameters.throat = throat; parameters.radius = radius; parameters.depth = depth
        #expect(parameters.isValid)
        let mesh = try SurfaceMesh(parameters: parameters,columns: 8,rows: 8)
        #expect(mesh.vertices.allSatisfy { $0.position.y.isFinite && $0.normal.y.isFinite })
    } } }
}

@Test func coordinateGridIsBoundedAndContainsAxesAndTicks() {
    var grid = CoordinateGrid()
    #expect(!grid.visible)
    for divisions in [4,10,24] {
        grid.divisions = divisions
        #expect(grid.segments.count == divisions*18+3)
        #expect(grid.spacing*Double(divisions) == grid.extent)
        #expect(grid.segments.allSatisfy { segment in
            simd_length(segment.b-segment.a) > 0 && (0..<3).allSatisfy { abs(segment.a[$0]) <= 15 && abs(segment.b[$0]) <= 15 }
        })
        let axes = grid.segments.filter { simd_length($0.b-$0.a) == 30 }
        #expect(axes.count == divisions*12+3)
    }
    grid.divisions = 25
    #expect(!grid.isValid && grid.segments.isEmpty)
}
