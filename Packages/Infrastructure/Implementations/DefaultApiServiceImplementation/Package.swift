// swift-tools-version: 6.0
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
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
        .package(path: "../../ApiService"),
        .package(path: "../../Base"),
    ],
    targets: [
        .target(
            name: "DefaultApiServiceImplementation",
            dependencies: ["Logging", "Networking", "ApiService", "Base"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DefaultApiServiceImplementationTests",
            dependencies: ["DefaultApiServiceImplementation", "ApiService", "Logging"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
