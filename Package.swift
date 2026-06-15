// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WorldCupBar",
    platforms: [
        .macOS(.v14)
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
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .target(name: "WorldCupBarCore"),
        .executableTarget(
            name: "WorldCupBar",
            dependencies: [
                "WorldCupBarCore",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            exclude: ["Info.plist", "WorldCupBar.entitlements"]
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
