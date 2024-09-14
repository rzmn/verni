// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataTransferObjects",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DataTransferObjects",
            targets: ["DataTransferObjects"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base")
    ],
    targets: [
        .target(
            name: "DataTransferObjects",
            dependencies: ["Base"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
