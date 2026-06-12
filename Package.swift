// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WorldCupBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WorldCupBarCore",
            targets: ["WorldCupBarCore"]
        ),
        .executable(
            name: "WorldCupBar",
            targets: ["WorldCupBar"]
        )
    ],
    targets: [
        .target(name: "WorldCupBarCore"),
        .executableTarget(
            name: "WorldCupBar",
            dependencies: ["WorldCupBarCore"]
        ),
        .testTarget(
            name: "WorldCupBarCoreTests",
            dependencies: ["WorldCupBarCore"]
        )
    ]
)
