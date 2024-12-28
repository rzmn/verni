// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Base",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Base",
            targets: ["Base"]
        )
    ],
    dependencies: [
        .package(path: "../AsyncExtensions")
    ],
    targets: [
        .target(
            name: "Base",
            dependencies: [
                "AsyncExtensions"
            ]
        )
    ]
)
