// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Api",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Api",
            targets: ["Api"]
        )
    ],
    dependencies: [
        .package(path: "../DataTransferObjects")
    ],
    targets: [
        .target(
            name: "Api",
            dependencies: ["DataTransferObjects"]
        )
    ]
)
