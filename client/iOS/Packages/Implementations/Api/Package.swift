// swift-tools-version: 5.10
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
        ),
    ],
    dependencies: [
        .package(path: "../ApiService"),
        .package(path: "../Base"),
        .package(path: "../DataTransferObjects"),
    ],
    targets: [
        .target(
            name: "Api",
            dependencies: ["ApiService", "Base", "DataTransferObjects"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
