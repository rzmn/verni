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
        .package(path: "../../../Infrastructure/Filesystem"),
        .package(path: "../../../Infrastructure/DI/Infrastructure"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
    ],
    targets: [
        .target(
            name: "PersistentStorageSQLite",
            dependencies: [
                "DataTransferObjects",
                "Logging",
                "Filesystem",
                "PersistentStorage",
                "Infrastructure",
                .product(name: "SQLite", package: "SQLite.swift"),
            ]
        ),
        .testTarget(
            name: "PersistentStorageSQLiteTests",
            dependencies: [
                "DataTransferObjects",
                "Logging",
                "PersistentStorage",
                "PersistentStorageSQLite",
                "TestInfrastructure",
            ]
        ),
    ]
)
