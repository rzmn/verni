// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestFilesystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TestFilesystem",
            targets: ["TestFilesystem"]
        )
    ],
    dependencies: [
        .package(path: "../../Filesystem"),
        .package(path: "../../Logging"),
        .package(path: "../../Base"),
    ],
    targets: [
        .target(
            name: "TestFilesystem",
            dependencies: [
                "Filesystem",
                "Logging",
                "Base",
            ]
        )
    ]
)
