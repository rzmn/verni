// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultUsersRepositoryImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultUsersRepositoryImplementation",
            targets: ["DefaultUsersRepositoryImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/DataTransferObjects"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Data/Implementations/MockPersistentStorage"),
        .package(path: "../../../Data/Implementations/MockApiImplementation"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultUsersRepositoryImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "DataTransferObjects",
                "PersistentStorage",
                "Logging",
                "Base",
            ]
        ),
        .testTarget(
            name: "DefaultUsersRepositoryImplementationTests",
            dependencies: [
                "DefaultUsersRepositoryImplementation",
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "DataTransferObjects",
                "PersistentStorage",
                "Logging",
                "Base",
                "TestInfrastructure",
                "MockPersistentStorage",
                "MockApiImplementation",
            ]
        ),
    ]
)
