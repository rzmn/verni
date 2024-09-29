// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SignUpScreen",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SignUpScreen",
            targets: ["SignUpScreen"]
        )
    ],
    dependencies: [
        .package(path: "../../AppBase"),
        .package(path: "../../DesignSystem"),
        .package(path: "../../../DI/DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base"),
        .package(url: "https://github.com/rzmn/ProgressHUD.git", branch: "rzmn/without-privacy-manifest")
    ],
    targets: [
        .target(
            name: "SignUpScreen",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "ProgressHUD",
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
