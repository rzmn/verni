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
        .package(path: "../Screens/AuthWelcomeScreen"),
        .package(path: "../Screens/DebugMenuScreen"),
        .package(path: "../Screens/SpendingsScreen"),
        .package(path: "../Screens/ProfileScreen"),
        .package(path: "../Screens/LogInScreen"),
        .package(path: "../../DI/DI"),
        .package(path: "../../Domain/Domain"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Infrastructure/Base")
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
                "AppBase",
                "AuthWelcomeScreen",
                "DebugMenuScreen",
                "LogInScreen",
                "SpendingsScreen",
                "ProfileScreen"
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
