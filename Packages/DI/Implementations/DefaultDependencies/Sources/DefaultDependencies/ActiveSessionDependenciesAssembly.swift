import DI
import Domain
import AsyncExtensions
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

final class ActiveSessionDependenciesAssemblyFactory: ActiveSessionDIContainerFactory {
    let defaultDependencies: DefaultDependenciesAssembly

    init(defaultDependencies: DefaultDependenciesAssembly) {
        self.defaultDependencies = defaultDependencies
    }

    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: AsyncSubject<LogoutReason>,
        userId: User.ID
    ) async -> ActiveSessionDIContainer {
        await ActiveSessionDependenciesAssembly(
            api: api,
            persistency: persistency,
            longPoll: longPoll,
            defaultDependencies: defaultDependencies,
            logoutSubject: logoutSubject,
            userId: userId
        )
    }
}

final class ActiveSessionDependenciesAssembly: ActiveSessionDIContainer {
    private let api: ApiProtocol
    private let persistency: Persistency
    private let longPoll: LongPoll

    private let logoutSubject: AsyncSubject<LogoutReason>
    private let updatableProfile  = ExternallyUpdatable<Domain.Profile>(
        taskFactory: DefaultTaskFactory()
    )
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

    let userId: User.ID

    init(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        defaultDependencies: DefaultDependenciesAssembly,
        logoutSubject: AsyncSubject<LogoutReason>,
        userId: User.ID
    ) async {
        self.api = api
        self.persistency = persistency
        self.longPoll = longPoll
        self.defaultDependencies = defaultDependencies
        self.logoutSubject = logoutSubject
        self.userId = userId
        let spendingsOfflineRepository = DefaultSpendingsOfflineRepository(persistency: persistency)
        self.spendingsOfflineRepository = spendingsOfflineRepository
        let friendsOfflineRepository = DefaultFriendsOfflineRepository(persistency: persistency)
        self.friendsOfflineRepository = friendsOfflineRepository
        let profileOfflineRepository = DefaultProfileOfflineRepository(persistency: persistency)
        self.profileOfflineRepository = profileOfflineRepository
        let usersOfflineRepository = DefaultUsersOfflineRepository(persistency: persistency)
        self.usersOfflineRepository = usersOfflineRepository
        profileRepository = await DefaultProfileRepository(
            api: api,
            logger: .shared.with(prefix: "[profile.repo] "),
            offline: profileOfflineRepository,
            profile: updatableProfile,
            taskFactory: DefaultTaskFactory()
        )
        usersRepository = DefaultUsersRepository(
            api: api,
            logger: .shared.with(prefix: "[users.repo] "),
            offline: usersOfflineRepository,
            taskFactory: DefaultTaskFactory()
        )
        spendingsRepository = await DefaultSpendingsRepository(
            api: api,
            longPoll: longPoll,
            logger: .shared.with(prefix: "[spendings.repo] "),
            offline: spendingsOfflineRepository,
            taskFactory: DefaultTaskFactory()
        )
        friendListRepository = DefaultFriendsRepository(
            api: api,
            longPoll: longPoll,
            logger: .shared.with(prefix: "[friends.repo] "),
            offline: friendsOfflineRepository,
            taskFactory: DefaultTaskFactory()
        )
        logoutUseCase = await DefaultLogoutUseCase(
            persistency: persistency,
            shouldLogout: logoutSubject,
            taskFactory: DefaultTaskFactory(),
            logger: .shared.with(prefix: "[logout] ")
        )
    }

    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase {
        DefaultSpendingInteractionsUseCase(
            api: api
        )
    }

    func profileEditingUseCase() -> ProfileEditingUseCase {
        DefaultProfileEditingUseCase(
            api: api,
            persistency: persistency,
            taskFactory: DefaultTaskFactory(),
            avatarsRepository: defaultDependencies.avatarsOfflineMutableRepository,
            profile: updatableProfile
        )
    }

    func pushRegistrationUseCase() -> PushRegistrationUseCase {
        DefaultPushRegistrationUseCase(
            api: api,
            logger: .shared.with(prefix: "[push] ")
        )
    }

    func friendInterationsUseCase() -> FriendInteractionsUseCase {
        DefaultFriendInteractionsUseCase(
            api: api
        )
    }

    func emailConfirmationUseCase() -> EmailConfirmationUseCase {
        DefaultEmailConfirmationUseCase(
            api: api
        )
    }

    func qrInviteUseCase() -> QRInviteUseCase {
        DefaultQRInviteUseCase()
    }

    func receivingPushUseCase() -> ReceivingPushUseCase {
        DefaultReceivingPushUseCase(
            usersRepository: usersRepository,
            friendsRepository: friendListRepository,
            spendingsRepository: spendingsRepository,
            logger: .shared.with(prefix: "[push.r] ")
        )
    }
}
