// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MockPersistentStorage",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MockPersistentStorage",
            targets: ["MockPersistentStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../../PersistentStorage"),
        .package(path: "../../DataTransferObjects"),
        .package(path: "../../../Infrastructure/Logging"),
    ],
    targets: [
        .target(
            name: "MockPersistentStorage",
            dependencies: [
                "DataTransferObjects",
                "Logging", 
                "PersistentStorage",
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        ),
    ]
)
