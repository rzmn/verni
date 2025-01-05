// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultProfileRepositoryImplementation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultProfileRepositoryImplementation",
            targets: ["DefaultProfileRepositoryImplementation"]
        )
    ],
    dependencies: [
        .package(path: "../ApiDomainConvenience"),
        .package(path: "../../Domain"),
        .package(path: "../../../Infrastructure/Base"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Data/Implementations/MockPersistentStorage"),
        .package(path: "../../../Data/Implementations/MockApiImplementation"),
        .package(path: "../../../Infrastructure/Implementations/TestInfrastructure"),
    ],
    targets: [
        .target(
            name: "DefaultProfileRepositoryImplementation",
            dependencies: [
                "Domain",
                "Api",
                "ApiDomainConvenience",
                "PersistentStorage",
            ]
        ),
        .testTarget(
            name: "DefaultProfileRepositoryImplementationTests",
            dependencies: [
                "Domain",
                "Api",
                "Base",
                "ApiDomainConvenience",
                "PersistentStorage",
                "DefaultProfileRepositoryImplementation",
                "MockPersistentStorage",
                "MockApiImplementation",
                "TestInfrastructure"
            ]
        ),
    ]
)
