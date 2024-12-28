// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultPushRegistrationUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultPushRegistrationUseCaseImplementation",
            targets: ["DefaultPushRegistrationUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
        .package(path: "../../../Data/PersistentStorage"),
    ],
    targets: [
        .target(
            name: "DefaultPushRegistrationUseCaseImplementation",
            dependencies: [
                "Domain", "Api", "ApiDomainConvenience", "DataTransferObjects", "PersistentStorage",
            ]
        )
    ]
)
