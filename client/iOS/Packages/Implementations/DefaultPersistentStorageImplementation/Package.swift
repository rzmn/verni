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
        .package(path: "../../DataTransferObjects"),
        .package(path: "../../Shared/Logging"),
    ],
    targets: [
        .target(
            name: "DefaultPersistentStorageImplementation",
            dependencies: ["DataTransferObjects", "Logging", "PersistentStorage"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
