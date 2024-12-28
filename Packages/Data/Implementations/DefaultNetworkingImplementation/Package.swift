// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultNetworkingImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultNetworkingImplementation",
            targets: ["DefaultNetworkingImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../../Networking"),
        .package(path: "../../../Infrastructure/Filesystem"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultNetworkingImplementation",
            dependencies: [
                "Logging",
                "Networking",
                "Filesystem",
                "Base",
            ]
        ),
        .testTarget(
            name: "DefaultNetworkingImplementationTests",
            dependencies: [
                "Logging",
                "Networking",
                "Filesystem",
                "Base",
                "DefaultNetworkingImplementation",
                "TestInfrastructure",
            ]
        ),
    ]
)
