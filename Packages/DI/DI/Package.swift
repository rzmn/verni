// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DI",
            targets: ["DI"]
        )
    ],
    dependencies: [
        .package(path: "../../Domain/Domain")
    ],
    targets: [
        .target(
            name: "DI",
            dependencies: [
                "Domain"
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
