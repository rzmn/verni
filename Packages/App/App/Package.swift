// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "App",
            targets: ["App"]
        )
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../AppBase"),
        .package(path: "../Flows/AuthenticatedFlow"),
        .package(path: "../Flows/UnauthenticatedFlow"),
        .package(path: "../../DI/DI"),
        .package(path: "../../Domain/Domain"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Infrastructure/Base"),
        .package(url: "https://github.com/rzmn/ProgressHUD.git", branch: "rzmn/without-privacy-manifest")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "ProgressHUD",
                "AppBase",
                "AuthenticatedFlow",
                "UnauthenticatedFlow"
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
