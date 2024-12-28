// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpendingsScreen",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SpendingsScreen",
            targets: ["SpendingsScreen"]
        )
    ],
    dependencies: [
        .package(path: "../../AppBase"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../../DI/DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base"),
    ],
    targets: [
        .target(
            name: "SpendingsScreen",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "AppBase",
            ]
        )
    ]
)
