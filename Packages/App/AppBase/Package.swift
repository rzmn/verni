// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppBase",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppBase",
            targets: ["AppBase"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Domain/Domain"),
        .package(path: "../../DesignSystem"),
        .package(url: "https://github.com/Ekhoo/Device.git", from: "3.7.0"),
    ],
    targets: [
        .target(
            name: "AppBase",
            dependencies: [
                "Base",
                "Logging",
                "Domain",
                "DesignSystem",
                "Device",
            ]
        )
    ]
)
