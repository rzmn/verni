// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersistentStorageSQLite",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PersistentStorageSQLite",
            targets: ["PersistentStorageSQLite"]
        )
    ],
    dependencies: [
        .package(path: "../../PersistentStorage"),
        .package(path: "../../DataTransferObjects"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ],
    targets: [
        .target(
            name: "PersistentStorageSQLite",
            dependencies: [
                "DataTransferObjects",
                "Logging",
                "PersistentStorage",
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PersistentStorageSQLiteTests",
            dependencies: [
                "DataTransferObjects",
                "Logging",
                "PersistentStorage",
                "PersistentStorageSQLite"
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
