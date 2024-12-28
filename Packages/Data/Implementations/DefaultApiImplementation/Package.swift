// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultApiImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultApiImplementation",
            targets: ["DefaultApiImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../../Api"),
        .package(path: "../../DataTransferObjects"),
        .package(path: "../../ApiService"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultApiImplementation",
            dependencies: [
                "ApiService",
                "Api",
                "Base",
                "DataTransferObjects",
                "Logging",
            ]
        ),
        .testTarget(
            name: "DefaultApiImplementationTests",
            dependencies: [
                "DefaultApiImplementation",
                "ApiService",
                "Api",
                "Base",
                "DataTransferObjects",
                "TestInfrastructure"
            ]
        ),
    ]
)
