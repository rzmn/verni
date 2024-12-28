// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/AsyncExtensions")
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                "AsyncExtensions"
            ]
        )
    ]
)
