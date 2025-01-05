// swift-tools-version: 6.0
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
        )
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../../DI/DI"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DI/DataLayerDependencies"),
    ],
    targets: [
        .target(
            name: "DefaultAuthUseCaseImplementation",
            dependencies: [
                "Domain",
                "Api",
                "DI",
                "DataLayerDependencies",
            ]
        )
    ]
)
