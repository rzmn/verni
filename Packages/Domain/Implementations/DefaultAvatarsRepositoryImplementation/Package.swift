// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultAvatarsRepositoryImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultAvatarsRepositoryImplementation",
            targets: ["DefaultAvatarsRepositoryImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Data/Implementations/MockApiImplementation"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultAvatarsRepositoryImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "DataTransferObjects",
                "PersistentStorage",
                "Base",
                "Logging",
            ]
        ),
        .testTarget(
            name: "DefaultAvatarsRepositoryImplementationTests",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "DataTransferObjects",
                "PersistentStorage",
                "DefaultAvatarsRepositoryImplementation",
                "Base",
                "Logging",
                "MockApiImplementation",
                "TestInfrastructure"
            ]
        ),
    ]
)
