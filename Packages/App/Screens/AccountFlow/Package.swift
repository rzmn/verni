// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AccountFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AccountFlow",
            targets: ["AccountFlow"]
        )
    ],
    dependencies: [
        .package(path: "../UpdateAvatarFlow"),
        .package(path: "../QrPreviewFlow"),
        .package(path: "../UpdateDisplayNameFlow"),
        .package(path: "../UpdateEmailFlow"),
        .package(path: "../UpdatePasswordFlow"),
        .package(path: "../../AppBase"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../../DI/DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base")
    ],
    targets: [
        .target(
            name: "AccountFlow",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "AppBase",
                "UpdateEmailFlow",
                "UpdateDisplayNameFlow",
                "UpdatePasswordFlow",
                "QrPreviewFlow",
                "UpdateAvatarFlow"
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
