// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuthenticatedFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AuthenticatedFlow",
            targets: ["AuthenticatedFlow"]
        )
    ],
    dependencies: [
        .package(path: "../AccountFlow"),
        .package(path: "../FriendsFlow"),
        .package(path: "../AddExpenseFlow"),
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
            name: "AuthenticatedFlow",
            dependencies: [
                "DesignSystem",
                "DI",
                "Domain",
                "Logging",
                "Base",
                "ProgressHUD",
                "AppBase",
                "AccountFlow",
                "FriendsFlow",
                "AddExpenseFlow"
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
