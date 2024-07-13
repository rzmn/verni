// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        ),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../../Interfaces/DI"),
        .package(path: "../../Interfaces/Domain"),
        .package(path: "../../Shared/Logging"),
        .package(path: "../../Shared/Base"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base"
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
