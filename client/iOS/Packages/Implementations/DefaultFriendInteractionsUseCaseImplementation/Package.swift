// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultFriendInteractionsUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultFriendInteractionsUseCaseImplementation",
            targets: ["DefaultFriendInteractionsUseCaseImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Interfaces/Domain"),
        .package(path: "../Api"),
        .package(path: "../ApiDomainConvenience"),
    ],
    targets: [
        .target(
            name: "DefaultFriendInteractionsUseCaseImplementation",
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
