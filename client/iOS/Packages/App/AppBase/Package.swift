// swift-tools-version: 5.10
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
        ),
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base"),
    ],
    targets: [
        .target(
            name: "AppBase",
            dependencies: [
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
