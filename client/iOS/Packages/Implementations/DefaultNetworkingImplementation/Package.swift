// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultNetworkingImplementation",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DefaultNetworkingImplementation",
            targets: ["DefaultNetworkingImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
    ],
    targets: [
        .target(
            name: "DefaultNetworkingImplementation",
            dependencies: ["Domain", "Logging", "Networking"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
