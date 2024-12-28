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
        .package(path: "../../DataTransferObjects"),
        .package(path: "../../Api"),
        .package(path: "../../PersistentStorage"),
        .package(path: "../../ApiService"),
        .package(path: "../../Networking"),
        .package(path: "../../../Infrastructure/AsyncExtensions"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../DefaultNetworkingImplementation"),
        .package(path: "../DefaultApiServiceImplementation"),
        .package(path: "../PersistentStorageSQLite"),
        .package(path: "../DefaultApiImplementation"),
    ],
    targets: [
        .target(
            name: "DefaultDataLayerDependencies",
            dependencies: [
                "DataLayerDependencies",
                "DataTransferObjects",
                "PersistentStorage",
                "Api",
                "DefaultNetworkingImplementation",
                "DefaultApiServiceImplementation",
                "PersistentStorageSQLite",
                "DefaultApiImplementation",
                "AsyncExtensions",
                "Base",
                "ApiService",
                "Networking",
            ]
        )
    ]
)
