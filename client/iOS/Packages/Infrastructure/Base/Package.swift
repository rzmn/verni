// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Base",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Base",
            targets: ["Base"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Base",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
