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
        .package(path: "../../DI"),
        .package(path: "../../../Domain/Domain"),
        .package(path: "../../../Domain/Implementations/DefaultAuthUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultUsersRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultFriendsRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultFriendInteractionsUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultQRInviteUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultSpendingInteractionsUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultSpendingsRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultProfileEditingUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultValidationUseCasesImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultAvatarsRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultEmailConfirmationUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultPushRegistrationUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultSaveCredendialsUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultProfileRepositoryImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultLogoutUseCaseImplementation"),
        .package(path: "../../../Domain/Implementations/DefaultReceivingPushUseCaseImplementation"),

        .package(path: "../../../Infrastructure/Networking"),
        .package(path: "../../../Infrastructure/Logging"),
        .package(path: "../../../Infrastructure/ApiService"),
        .package(path: "../../../Infrastructure/AuthSession"),
        .package(path: "../../../Infrastructure/Implementations/DefaultNetworkingImplementation"),
        .package(path: "../../../Infrastructure/Implementations/DefaultApiServiceImplementation"),

        .package(path: "../../../Data/PersistentStorage"),
        .package(path: "../../../Data/Api"),
        .package(path: "../../../Data/Implementations/PersistentStorageSQLite"),
        .package(path: "../../../Data/Implementations/DefaultApiImplementation"),
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
                "PersistentStorageSQLite",
                "DefaultApiImplementation",
                "DefaultProfileEditingUseCaseImplementation",
                "DefaultValidationUseCasesImplementation",
                "DefaultAvatarsRepositoryImplementation",
                "DefaultEmailConfirmationUseCaseImplementation",
                "DefaultPushRegistrationUseCaseImplementation",
                "DefaultSaveCredendialsUseCaseImplementation",
                "DefaultProfileRepositoryImplementation",
                "DefaultLogoutUseCaseImplementation",
                "DefaultReceivingPushUseCaseImplementation",
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
