import DI
import Domain
import AsyncExtensions
internal import Logging
internal import Base
internal import Api
internal import ApiService
internal import DefaultApiImplementation
internal import Networking
internal import PersistentStorage
internal import PersistentStorageSQLite
internal import DefaultAuthUseCaseImplementation
internal import DefaultApiServiceImplementation
internal import DefaultNetworkingImplementation
internal import DefaultUsersRepositoryImplementation
internal import DefaultFriendsRepositoryImplementation
internal import DefaultFriendInteractionsUseCaseImplementation
internal import DefaultQRInviteUseCaseImplementation
internal import DefaultSpendingInteractionsUseCaseImplementation
internal import DefaultSpendingsRepositoryImplementation
internal import DefaultProfileEditingUseCaseImplementation
internal import DefaultValidationUseCasesImplementation
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultEmailConfirmationUseCaseImplementation
internal import DefaultPushRegistrationUseCaseImplementation
internal import DefaultSaveCredendialsUseCaseImplementation
internal import DefaultProfileRepositoryImplementation
internal import DefaultLogoutUseCaseImplementation
internal import DefaultReceivingPushUseCaseImplementation
internal import DataLayerDependencies

final class ActiveSessionDependenciesAssembly: AuthenticatedDomainLayerSession {
    private let dataLayer: AuthenticatedDataLayerSession
    private let logoutSubject: AsyncSubject<LogoutReason>
    private let updatableProfile: ExternallyUpdatable<Domain.Profile>
    private let logger: Logger
    var appCommon: AppCommon {
        defaultDependencies.appCommon
    }
    let defaultDependencies: DefaultDependenciesAssembly
    let profileRepository: ProfileRepository
    let usersRepository: UsersRepository
    let spendingsRepository: SpendingsRepository
    let friendListRepository: FriendsRepository
    let spendingsOfflineRepository: SpendingsOfflineRepository
    let friendsOfflineRepository: FriendsOfflineRepository
    let profileOfflineRepository: ProfileOfflineRepository
    let usersOfflineRepository: UsersOfflineRepository

    let logoutUseCase: LogoutUseCase

    let userId: User.Identifier

    init(
        defaultDependencies: DefaultDependenciesAssembly,
        dataLayer: AuthenticatedDataLayerSession
    ) async {
        self.logger = defaultDependencies.infrastructure.logger.with(prefix: "👩🏿‍💻")
        self.defaultDependencies = defaultDependencies
        let profileLogger = logger.with(prefix: "🪪")
        updatableProfile = ExternallyUpdatable<Domain.Profile>(
            taskFactory: defaultDependencies.infrastructure.taskFactory,
            logger: profileLogger
        )
        let logoutLogger = logger.with(prefix: "🚪")
        self.logoutSubject = AsyncSubject<LogoutReason>(
            taskFactory: defaultDependencies.infrastructure.taskFactory,
            logger: logoutLogger
        )
        self.dataLayer = dataLayer
        userId = await dataLayer.persistency.userId
        let spendingsOfflineRepository = DefaultSpendingsOfflineRepository(persistency: dataLayer.persistency)
        self.spendingsOfflineRepository = spendingsOfflineRepository
        let friendsOfflineRepository = DefaultFriendsOfflineRepository(persistency: dataLayer.persistency)
        self.friendsOfflineRepository = friendsOfflineRepository
        let profileOfflineRepository = DefaultProfileOfflineRepository(persistency: dataLayer.persistency)
        self.profileOfflineRepository = profileOfflineRepository
        let usersOfflineRepository = DefaultUsersOfflineRepository(persistency: dataLayer.persistency)
        self.usersOfflineRepository = usersOfflineRepository
        profileRepository = await DefaultProfileRepository(
            api: dataLayer.api,
            logger: profileLogger,
            offline: profileOfflineRepository,
            profile: updatableProfile,
            taskFactory: defaultDependencies.infrastructure.taskFactory
        )
        usersRepository = DefaultUsersRepository(
            api: dataLayer.api,
            logger: logger.with(prefix: "🎭"),
            offline: usersOfflineRepository,
            taskFactory: defaultDependencies.infrastructure.taskFactory
        )
        spendingsRepository = await DefaultSpendingsRepository(
            api: dataLayer.api,
            longPoll: dataLayer.longPoll,
            logger: logger.with(prefix: "💸"),
            offline: spendingsOfflineRepository,
            taskFactory: defaultDependencies.infrastructure.taskFactory
        )
        friendListRepository = DefaultFriendsRepository(
            api: dataLayer.api,
            longPoll: dataLayer.longPoll,
            logger: logger.with(prefix: "🤝"),
            offline: friendsOfflineRepository,
            taskFactory: defaultDependencies.infrastructure.taskFactory
        )
        logoutUseCase = await DefaultLogoutUseCase(
            session: dataLayer,
            shouldLogout: logoutSubject,
            taskFactory: defaultDependencies.infrastructure.taskFactory,
            logger: logoutLogger
        )
    }

    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase {
        DefaultSpendingInteractionsUseCase(
            api: dataLayer.api
        )
    }

    func profileEditingUseCase() -> ProfileEditingUseCase {
        DefaultProfileEditingUseCase(
            api: dataLayer.api,
            persistency: dataLayer.persistency,
            taskFactory: defaultDependencies.infrastructure.taskFactory,
            avatarsRepository: defaultDependencies.avatarsOfflineMutableRepository,
            profile: updatableProfile
        )
    }

    func pushRegistrationUseCase() -> PushRegistrationUseCase {
        DefaultPushRegistrationUseCase(
            api: dataLayer.api,
            logger: logger.with(prefix: "🔔")
        )
    }

    func friendInterationsUseCase() -> FriendInteractionsUseCase {
        DefaultFriendInteractionsUseCase(
            api: dataLayer.api
        )
    }

    func emailConfirmationUseCase() -> EmailConfirmationUseCase {
        DefaultEmailConfirmationUseCase(
            api: dataLayer.api
        )
    }

    func qrInviteUseCase() -> QRInviteUseCase {
        DefaultQRInviteUseCase(
            logger: logger.with(prefix: "🏙️"),
            urlById: { AppUrl.users(.show(id: $0)).url }
        )
    }

    func receivingPushUseCase() -> ReceivingPushUseCase {
        DefaultReceivingPushUseCase(
            usersRepository: usersRepository,
            friendsRepository: friendListRepository,
            spendingsRepository: spendingsRepository,
            logger: logger.with(prefix: "🔔")
        )
    }
}
