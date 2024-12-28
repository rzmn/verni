// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestAsyncExtensions",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TestAsyncExtensions",
            targets: ["TestAsyncExtensions"]
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
            name: "TestAsyncExtensions",
            dependencies: [
                "Filesystem",
                "Logging",
                "Base",
                "AsyncExtensions"
            ]
        )
    ]
)
