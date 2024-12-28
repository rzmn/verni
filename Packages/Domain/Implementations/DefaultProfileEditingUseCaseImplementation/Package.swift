// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultProfileEditingUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultProfileEditingUseCaseImplementation",
            targets: ["DefaultProfileEditingUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
    ],
    targets: [
        .target(
            name: "DefaultProfileEditingUseCaseImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience"]
        )
    ]
)
