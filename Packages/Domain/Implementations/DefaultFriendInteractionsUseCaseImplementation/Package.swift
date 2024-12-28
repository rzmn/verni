// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultFriendInteractionsUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultFriendInteractionsUseCaseImplementation",
            targets: ["DefaultFriendInteractionsUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
    ],
    targets: [
        .target(
            name: "DefaultFriendInteractionsUseCaseImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience"]
        )
    ]
)
