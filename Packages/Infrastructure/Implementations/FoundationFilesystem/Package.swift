// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoundationFilesystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FoundationFilesystem",
            targets: ["FoundationFilesystem"]
        )
    ],
    dependencies: [
        .package(path: "../../Filesystem"),
        .package(path: "../../Logging"),
        .package(path: "../../Base")
    ],
    targets: [
        .target(
            name: "FoundationFilesystem",
            dependencies: [
                "Filesystem",
                "Logging",
                "Base"
            ]
        ),
        .testTarget(
            name: "FoundationFilesystemTests",
            dependencies: [
                "FoundationFilesystem",
                "Filesystem",
                "Logging",
                "Base"
            ]
        )
    ]
)
