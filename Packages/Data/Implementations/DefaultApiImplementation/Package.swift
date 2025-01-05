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
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
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
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
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
