// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultReceivingPushUseCaseImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultReceivingPushUseCaseImplementation",
            targets: ["DefaultReceivingPushUseCaseImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base"),
    ],
    targets: [
        .target(
            name: "DefaultReceivingPushUseCaseImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
                "Logging",
                "Base",
            ]
        ),
        .testTarget(
            name: "DefaultReceivingPushUseCaseImplementationTests",
            dependencies: [
                "DefaultReceivingPushUseCaseImplementation", "Domain", "Api", "Logging", "Base",
            ]
        ),
    ]
)
