// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultAsyncExtensions",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultAsyncExtensions",
            targets: ["DefaultAsyncExtensions"]
        )
    ],
    dependencies: [
        .package(path: "../../Filesystem"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
        .package(path: "../../AsyncExtensions")
    ],
    targets: [
        .target(
            name: "DefaultAsyncExtensions",
            dependencies: [
                "Filesystem",
                "Logging",
                "Base",
                "AsyncExtensions"
            ]
        )
    ]
)
