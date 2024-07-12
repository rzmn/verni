// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Api",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Api",
            targets: ["Api"]
        ),
    ],
    dependencies: [
        .package(path: "../ApiService"),
        .package(path: "../Base"),
    ],
    targets: [
        .target(
            name: "Api",
            dependencies: ["ApiService", "Base"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
