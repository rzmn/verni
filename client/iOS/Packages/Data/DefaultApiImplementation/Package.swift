// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultApiImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultApiImplementation",
            targets: ["DefaultApiImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../Api"),
        .package(path: "../DataTransferObjects"),
        .package(path: "../../Infrastructure/ApiService"),
        .package(path: "../../Infrastructure/Base"),
    ],
    targets: [
        .target(
            name: "DefaultApiImplementation",
            dependencies: ["ApiService", "Api", "Base", "DataTransferObjects"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
