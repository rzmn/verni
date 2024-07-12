// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApiDomainConvenience",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ApiDomainConvenience",
            targets: ["ApiDomainConvenience"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Api"),
    ],
    targets: [
        .target(
            name: "ApiDomainConvenience",
            dependencies: ["Domain", "Api"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
