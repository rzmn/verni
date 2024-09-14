// swift-tools-version: 6.0
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
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Data/Implementations/MockPersistentStorage"),
        .package(path: "../../../Data/Implementations/MockApiImplementation")
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
        ),
        .testTarget(
            name: "DefaultSpendingsRepositoryImplementationTests",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "DataTransferObjects",
                "PersistentStorage",
                "DefaultSpendingsRepositoryImplementation",
                "MockPersistentStorage",
                "MockApiImplementation"
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
