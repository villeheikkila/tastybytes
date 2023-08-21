// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Models",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "Models",
            targets: ["Models"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", .upToNextMajor(from: "4.1.1")),
        .package(name: "Extensions", path: "../Extensions"),
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: ["SFSafeSymbols", .product(name: "Extensions", package: "Extensions")]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"]
        ),
    ]
)
