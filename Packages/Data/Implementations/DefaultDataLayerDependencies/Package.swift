// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultDataLayerDependencies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultDataLayerDependencies",
            targets: ["DefaultDataLayerDependencies"]
        )
    ],
    dependencies: [
        .package(path: "../../DI/DataLayerDependencies"),
        .package(path: "../../Api"),
        .package(path: "../../PersistentStorage"),
        .package(path: "../../../Infrastructure/AsyncExtensions"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../PersistentStorageSQLite"),
        .package(path: "../DefaultApiImplementation"),
    ],
    targets: [
        .target(
            name: "DefaultDataLayerDependencies",
            dependencies: [
                "DataLayerDependencies",
                "PersistentStorage",
                "Api",
                "PersistentStorageSQLite",
                "DefaultApiImplementation",
                "AsyncExtensions",
                "Base",
            ]
        )
    ]
)
