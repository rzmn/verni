// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MockNetworkingImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MockNetworkingImplementation",
            targets: ["MockNetworkingImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
    ],
    targets: [
        .target(
            name: "MockNetworkingImplementation",
            dependencies: [
                "Logging",
                "Networking",
                "Base",
            ]
        )
    ]
)
