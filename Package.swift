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
    dependencies: [
        .package(url: "https://github.com/TelemetryDeck/SwiftSDK.git", exact: "2.14.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .target(name: "WorldCupBarCore"),
        .executableTarget(
            name: "WorldCupBar",
            dependencies: [
                "WorldCupBarCore",
                .product(name: "TelemetryDeck", package: "SwiftSDK"),
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
        .testTarget(
            name: "WorldCupBarCoreTests",
            dependencies: ["WorldCupBarCore"]
        ),
        .testTarget(
            name: "WorldCupBarTests",
            dependencies: ["WorldCupBar", "WorldCupBarCore"]
        )
    ]
)
