// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthSession",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AuthSession",
            targets: ["AuthSession"]
        ),
    ],
    dependencies: [
        .package(path: "../Api"),
        .package(path: "../PersistentStorage")
    ],
    targets: [
        .target(
            name: "AuthSession",
            dependencies: ["Api", "PersistentStorage"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
