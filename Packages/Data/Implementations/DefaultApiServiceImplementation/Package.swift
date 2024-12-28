// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultApiServiceImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultApiServiceImplementation",
            targets: ["DefaultApiServiceImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../../Networking"),
        .package(path: "../../ApiService"),
        .package(path: "../MockNetworkingImplementation"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultApiServiceImplementation",
            dependencies: [
                "Logging",
                "Networking",
                "ApiService",
                "Base",
            ]
        ),
        .testTarget(
            name: "DefaultApiServiceImplementationTests",
            dependencies: [
                "DefaultApiServiceImplementation",
                "ApiService",
                "Logging",
                "MockNetworkingImplementation",
                "TestInfrastructure",
            ]
        ),
    ]
)
