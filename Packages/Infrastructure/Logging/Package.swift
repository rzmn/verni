// swift-tools-version: 6.0
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
        )
    ],
    targets: [
        .target(
            name: "Logging",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
