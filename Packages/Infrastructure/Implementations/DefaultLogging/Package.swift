// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultLogging",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultLogging",
            targets: ["DefaultLogging"]
        )
    ],
    dependencies: [
        .package(path: "../../Logging")
    ],
    targets: [
        .target(
            name: "DefaultLogging",
            dependencies: [
                "Logging"
            ]
        )
    ]
)
