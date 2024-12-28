// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OnDemandPolling",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OnDemandPolling",
            targets: ["OnDemandPolling"]
        )
    ],
    dependencies: [
        .package(path: "../Api"),
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/AsyncExtensions"),
        .package(path: "../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "OnDemandPolling",
            dependencies: [
                "Base",
                "AsyncExtensions",
                "Api",
            ]
        ),
        .testTarget(
            name: "OnDemandPollingTests",
            dependencies: [
                "Base",
                "AsyncExtensions",
                "Api",
                "OnDemandPolling",
                "TestInfrastructure",
            ]
        ),
    ]
)
