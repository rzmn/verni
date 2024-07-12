// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultFriendsRepositoryImplementation",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DefaultFriendsRepositoryImplementation",
            targets: ["DefaultFriendsRepositoryImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Api"),
        .package(path: "../../ApiDomainConvenience"),
    ],
    targets: [
        .target(
            name: "DefaultFriendsRepositoryImplementation",
            dependencies: ["Domain", "Api", "ApiDomainConvenience"],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
