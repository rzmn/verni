// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataLayerDependencies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DataLayerDependencies",
            targets: ["DataLayerDependencies"]
        )
    ],
    dependencies: [
        .package(path: "../../Api"),
        .package(path: "../../PersistentStorage"),
        .package(path: "../../../Infrastructure/DI/Infrastructure"),
    ],
    targets: [
        .target(
            name: "DataLayerDependencies",
            dependencies: [
                "Infrastructure",
                "PersistentStorage",
                "Api",
            ]
        )
    ]
)
