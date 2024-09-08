// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApiService",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ApiService",
            targets: ["ApiService"]
        ),
    ],
    targets: [
        .target(
            name: "ApiService",
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
    ]
)
