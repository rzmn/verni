// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Routing",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Routing",
            targets: ["Routing"]
        ),
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(url: "https://github.com/rzmn/ProgressHUD.git", branch: "rzmn/without-privacy-manifest"),
    ],
    targets: [
        .target(
            name: "Routing",
            dependencies: [
                "Base",
                "ProgressHUD",
                "Logging"
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
