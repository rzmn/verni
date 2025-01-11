// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RemoteSyncEngine",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RemoteSyncEngine",
            targets: ["RemoteSyncEngine"]
        )
    ],
    dependencies: [
        .package(path: "../Api"),
        .package(path: "../PersistentStorage"),
        .package(path: "../SyncEngine"),
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Infrastructure/AsyncExtensions"),
    ],
    targets: [
        .target(
            name: "RemoteSyncEngine",
            dependencies: [
                "Api",
                "SyncEngine",
                "PersistentStorage",
                "Base",
                "Logging",
                "AsyncExtensions",
            ]
        )
    ]
)
