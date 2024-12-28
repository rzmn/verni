// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultInfrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultInfrastructure",
            targets: ["DefaultInfrastructure"]
        )
    ],
    dependencies: [
        .package(path: "../../DI/Infrastructure"),
        .package(path: "../../Filesystem"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
        .package(path: "../FoundationFilesystem"),
        .package(path: "../DefaultAsyncExtensions"),
        .package(path: "../DefaultLogging")
    ],
    targets: [
        .target(
            name: "DefaultInfrastructure",
            dependencies: [
                "FoundationFilesystem",
                "DefaultAsyncExtensions",
                "DefaultLogging",
                "Infrastructure",
                "Filesystem",
                "Logging",
                "Base"
            ]
        )
    ]
)
