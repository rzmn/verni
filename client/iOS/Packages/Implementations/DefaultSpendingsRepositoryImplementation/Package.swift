// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultSpendingsRepositoryImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultSpendingsRepositoryImplementation",
            targets: ["DefaultSpendingsRepositoryImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Interfaces/Domain"),
        .package(path: "../../Interfaces/PersistentStorage"),
        .package(path: "../Api"),
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../DataTransferObjects"),
    ],
    targets: [
        .target(
            name: "DefaultSpendingsRepositoryImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience", "DataTransferObjects", "PersistentStorage"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
