// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersistentStorage",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersistentStorage",
            targets: ["PersistentStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../../Interface/Domain"),
    ],
    targets: [
        .target(
            name: "PersistentStorage",
            dependencies: ["Domain"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
