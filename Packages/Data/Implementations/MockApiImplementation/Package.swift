// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MockApiImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MockApiImplementation",
            targets: ["MockApiImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../../Api"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Logging"),
    ],
    targets: [
        .target(
            name: "MockApiImplementation",
            dependencies: [
                "Api",
                "Base",
                "Logging",
            ]
        )
    ]
)
