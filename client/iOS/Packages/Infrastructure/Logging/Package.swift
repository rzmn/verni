// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Logging",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Logging",
            targets: ["Logging"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Logging",
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
