// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultPersistentStorageImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultPersistentStorageImplementation",
            targets: ["DefaultPersistentStorageImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Interfaces/PersistentStorage"),
        .package(path: "../DataTransferObjects"),
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Shared/Logging"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
    ],
    targets: [
        .target(
            name: "DefaultPersistentStorageImplementation",
            dependencies: [
                "DataTransferObjects",
                "Logging", 
                "PersistentStorage",
                "ApiDomainConvenience",
                .product(name: "SQLite", package: "SQLite.swift"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DefaultPersistentStorageImplementationTests",
            dependencies: [
                "DataTransferObjects",
                "Logging",
                "PersistentStorage",
                "ApiDomainConvenience",
                "DefaultPersistentStorageImplementation",
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
