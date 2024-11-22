// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppBase",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppBase",
            targets: ["AppBase"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Domain/Domain"),
        .package(path: "../../DesignSystem")
    ],
    targets: [
        .target(
            name: "AppBase",
            dependencies: [
                "Base",
                "Logging",
                "Domain",
                "DesignSystem"
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
