// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultAuthorizedSessionRepositoryImplementation",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DefaultAuthorizedSessionRepositoryImplementation",
            targets: ["DefaultAuthorizedSessionRepositoryImplementation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Api"),
        .package(path: "../../ApiDomainConvenience"),
    ],
    targets: [
        .target(
            name: "DefaultAuthorizedSessionRepositoryImplementation",
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
