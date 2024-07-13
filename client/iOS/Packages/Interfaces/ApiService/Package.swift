// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApiService",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ApiService",
            targets: ["ApiService"]
        ),
    ],
    dependencies: [
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "ApiService",
            dependencies: ["Networking"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
    ]
)
