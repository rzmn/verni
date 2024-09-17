// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncExtensions",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AsyncExtensions",
            targets: ["AsyncExtensions"]
        )
    ],
    dependencies: [
        .package(path: "../Logging")
    ],
    targets: [
        .target(
            name: "AsyncExtensions",
            dependencies: [
                "Logging"
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
