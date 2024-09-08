// swift-tools-version: 6.0
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
    targets: [
        .target(
            name: "Base",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
