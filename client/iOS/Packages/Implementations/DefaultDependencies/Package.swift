// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DefaultDependencies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DefaultDependencies",
            targets: ["DefaultDependencies"]
        ),
    ],
    dependencies: [
        .package(path: "../../Interfaces/DI"),
        .package(path: "../../Interfaces/Domain"),
        .package(path: "../../Interfaces/Networking"),
        .package(path: "../../Shared/Logging"),
        .package(path: "../../Interfaces/ApiService"),
        .package(path: "../../Interfaces/PersistentStorage"),
        .package(path: "../Api"),
        .package(path: "../AuthSession"),
        .package(path: "../DefaultAuthUseCaseImplementation"),
        .package(path: "../DefaultNetworkingImplementation"),
        .package(path: "../DefaultApiServiceImplementation"),
        .package(path: "../DefaultUsersRepositoryImplementation"),
        .package(path: "../DefaultFriendsRepositoryImplementation"),
        .package(path: "../DefaultFriendInteractionsUseCaseImplementation"),
        .package(path: "../DefaultQRInviteUseCaseImplementation"),
        .package(path: "../DefaultSpendingInteractionsUseCaseImplementation"),
        .package(path: "../DefaultSpendingsRepositoryImplementation"),
        .package(path: "../DefaultPersistentStorageImplementation"),
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
                "PersistentStorage",
                "DefaultNetworkingImplementation",
                "DefaultApiServiceImplementation",
                "DefaultAuthUseCaseImplementation",
                "DefaultUsersRepositoryImplementation",
                "DefaultFriendsRepositoryImplementation",
                "DefaultFriendInteractionsUseCaseImplementation",
                "DefaultQRInviteUseCaseImplementation",
                "DefaultSpendingInteractionsUseCaseImplementation",
                "DefaultSpendingsRepositoryImplementation",
                "DefaultPersistentStorageImplementation",
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
