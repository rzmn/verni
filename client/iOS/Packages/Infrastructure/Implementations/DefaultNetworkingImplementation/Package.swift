// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultNetworkingImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultNetworkingImplementation",
            targets: ["DefaultNetworkingImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
    ],
    targets: [
        .target(
            name: "DefaultNetworkingImplementation",
            dependencies: ["Logging", "Networking", "Base"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DefaultNetworkingImplementationTests",
            dependencies: ["Logging", "Networking", "Base", "DefaultNetworkingImplementation"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
