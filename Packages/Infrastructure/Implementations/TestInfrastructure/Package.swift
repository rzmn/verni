// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestInfrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TestInfrastructure",
            targets: ["TestInfrastructure"]
        )
    ],
    dependencies: [
        .package(path: "../../DI/Infrastructure"),
        .package(path: "../../Filesystem"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
        .package(path: "../FoundationFilesystem"),
        .package(path: "../TestFilesystem"),
        .package(path: "../TestAsyncExtensions"),
        .package(path: "../DefaultLogging"),
    ],
    targets: [
        .target(
            name: "TestInfrastructure",
            dependencies: [
                "FoundationFilesystem",
                "TestFilesystem",
                "TestAsyncExtensions",
                "DefaultLogging",
                "Infrastructure",
                "Filesystem",
                "Logging",
                "Base",
            ]
        )
    ]
)
