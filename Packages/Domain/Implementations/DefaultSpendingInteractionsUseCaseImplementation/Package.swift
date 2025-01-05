// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultSpendingInteractionsUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultSpendingInteractionsUseCaseImplementation",
            targets: ["DefaultSpendingInteractionsUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
    ],
    targets: [
        .target(
            name: "DefaultSpendingInteractionsUseCaseImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
            ]
        )
    ]
)
