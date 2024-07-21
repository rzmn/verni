// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultApiServiceImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultApiServiceImplementation",
            targets: ["DefaultApiServiceImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
        .package(path: "../../ApiService"),
    ],
    targets: [
        .target(
            name: "DefaultApiServiceImplementation",
            dependencies: ["Domain", "Logging", "Networking", "ApiService"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
