// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SyncEngine",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SyncEngine",
            targets: ["SyncEngine"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/DI/DataLayerDependencies"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/Implementations/MockApiImplementation"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Data/Implementations/MockPersistentStorage"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "SyncEngine",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
                "Logging",
            ]
        ),
        .testTarget(
            name: "SyncEngineTests",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
                "SyncEngine",
                "MockPersistentStorage",
                "DataLayerDependencies",
                "MockApiImplementation",
                "TestInfrastructure",
            ]
        ),
    ]
)
