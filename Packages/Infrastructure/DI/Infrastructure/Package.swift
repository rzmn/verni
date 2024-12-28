// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]
        )
    ],
    dependencies: [
        .package(path: "../../Filesystem"),
        .package(path: "../../AsyncExtensions"),
        .package(path: "../../Logging")
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: [
                "Filesystem",
                "Logging",
                "AsyncExtensions"
            ]
        )
    ]
)
