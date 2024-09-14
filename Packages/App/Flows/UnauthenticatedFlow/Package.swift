// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnauthenticatedFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "UnauthenticatedFlow",
            targets: ["UnauthenticatedFlow"]
        )
    ],
    dependencies: [
        .package(path: "../SignInFlow"),
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
            name: "UnauthenticatedFlow",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "ProgressHUD",
                "AppBase",
                "SignInFlow"
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
