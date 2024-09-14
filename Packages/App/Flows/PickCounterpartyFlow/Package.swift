// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PickCounterpartyFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PickCounterpartyFlow",
            targets: ["PickCounterpartyFlow"]
        )
    ],
    dependencies: [
        .package(path: "../../AppBase"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../../DI/DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base")
    ],
    targets: [
        .target(
            name: "PickCounterpartyFlow",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "AppBase"
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
