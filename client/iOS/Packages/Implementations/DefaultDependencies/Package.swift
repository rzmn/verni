// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultDependencies",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DefaultDependencies",
            targets: ["DefaultDependencies"]
        ),
    ],
    dependencies: [
        .package(path: "../../DI"),
        .package(path: "../../Domain"),
        .package(path: "../../Networking"),
        .package(path: "../../Logging"),
        .package(path: "../../ApiService"),
        .package(path: "../../Api"),
        .package(path: "../../AuthSession"),
        .package(path: "../Implementations/DefaultAuthUseCaseImplementation"),
        .package(path: "../Implementations/DefaultNetworkingImplementation"),
        .package(path: "../Implementations/DefaultApiServiceImplementation"),
        .package(path: "../DefaultAuthorizedSessionRepositoryImplementation"),
        .package(path: "../DefaultFriendsRepositoryImplementation"),
        .package(path: "../DefaultFriendInteractionsUseCaseImplementation"),
        .package(path: "../DefaultQRInviteUseCaseImplementation"),
        .package(path: "../DefaultSpendingInteractionsUseCaseImplementation"),
        .package(path: "../DefaultSpendingsRepositoryImplementation"),
    ],
    targets: [
        .target(
            name: "DefaultDependencies",
            dependencies: [
                "DI",
                "Domain",
                "Networking",
                "Logging",
                "ApiService",
                "Api",
                "AuthSession",
                "DefaultNetworkingImplementation",
                "DefaultApiServiceImplementation",
                "DefaultAuthUseCaseImplementation",
                "DefaultAuthorizedSessionRepositoryImplementation",
                "DefaultFriendsRepositoryImplementation",
                "DefaultFriendInteractionsUseCaseImplementation",
                "DefaultQRInviteUseCaseImplementation",
                "DefaultSpendingInteractionsUseCaseImplementation",
                "DefaultSpendingsRepositoryImplementation",
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([
                    "-warnings-as-errors"
                ], .when(configuration: .debug))
            ]
        )
    ]
)
