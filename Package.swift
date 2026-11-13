// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CreativeMath",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CreativeMath", targets: ["CreativeMath"]),
               .executable(name: "LorenzValidation", targets: ["LorenzValidation"])],
    targets: [
        .target(name: "WorkspaceCore"),
        .target(name: "LorenzMetal", dependencies: ["WorkspaceCore"]),
        .target(name: "SurfaceMetal", dependencies: ["WorkspaceCore"]),
        .executableTarget(name: "CreativeMath", dependencies: ["WorkspaceCore", "LorenzMetal", "SurfaceMetal"]),
        .executableTarget(name: "LorenzValidation", dependencies: ["WorkspaceCore", "LorenzMetal"]),
        .testTarget(name: "WorkspaceCoreTests", dependencies: ["WorkspaceCore"]),
        .testTarget(name: "LorenzMetalTests", dependencies: ["WorkspaceCore", "LorenzMetal", "SurfaceMetal"])
    ]
)
