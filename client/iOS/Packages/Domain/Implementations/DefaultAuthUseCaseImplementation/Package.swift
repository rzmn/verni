// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultAuthUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultAuthUseCaseImplementation",
            targets: ["DefaultAuthUseCaseImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
        .package(path: "../../../Infrastructure/AuthSession"),
    ],
    targets: [
        .target(
            name: "DefaultAuthUseCaseImplementation",
            dependencies: ["Domain", "Api", "AuthSession", "DataTransferObjects"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
