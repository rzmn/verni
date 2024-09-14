// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultSaveCredendialsUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultSaveCredendialsUseCaseImplementation",
            targets: ["DefaultSaveCredendialsUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api")
    ],
    targets: [
        .target(
            name: "DefaultSaveCredendialsUseCaseImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
