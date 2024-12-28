// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                "Base"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
