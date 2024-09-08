// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApiDomainConvenience",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ApiDomainConvenience",
            targets: ["ApiDomainConvenience"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
    ],
    targets: [
        .target(
            name: "ApiDomainConvenience",
            dependencies: ["Domain", "Api", "DataTransferObjects"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
