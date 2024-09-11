import DI
import Domain
import Combine
internal import Base
internal import AuthSession
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
    private let appCommon: AppCommon

    init(appCommon: AppCommon) {
        self.appCommon = appCommon
    }

    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: PassthroughSubject<LogoutReason, Never>,
        userId: User.ID
    ) async -> ActiveSessionDIContainer {
        await ActiveSessionDependenciesAssembly(
            api: api,
            persistency: persistency,
            longPoll: longPoll,
            appCommon: appCommon,
            logoutSubject: logoutSubject,
            userId: userId
        )
    }
}

final class ActiveSessionDependenciesAssembly: ActiveSessionDIContainer {
    private let api: ApiProtocol
    private let persistency: Persistency
    private let longPoll: LongPoll
    private let logoutSubject: PassthroughSubject<LogoutReason, Never>

    let appCommon: AppCommon
    let profileRepository: ProfileRepository
    let usersRepository: UsersRepository
    let spendingsRepository: SpendingsRepository
    let friendListRepository: FriendsRepository

    let logoutUseCase: LogoutUseCase

    let userId: User.ID

    init(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        appCommon: AppCommon,
        logoutSubject: PassthroughSubject<LogoutReason, Never>,
        userId: User.ID
    ) async {
        self.api = api
        self.persistency = persistency
        self.longPoll = longPoll
        self.appCommon = appCommon
        self.logoutSubject = logoutSubject
        self.userId = userId

        profileRepository = await DefaultProfileRepository(
            api: api,
            logger: .shared.with(prefix: "[profile.repo] "),
            offline: DefaultProfileOfflineRepository(
                persistency: persistency
            ),
            taskFactory: DefaultTaskFactory()
        )
        usersRepository = DefaultUsersRepository(
            api: api,
            logger: .shared.with(prefix: "[users.repo] "),
            offline: DefaultUsersOfflineRepository(
                persistency: persistency
            ),
            taskFactory: DefaultTaskFactory()
        )
        spendingsRepository = DefaultSpendingsRepository(
            api: api,
            longPoll: longPoll,
            logger: .shared.with(prefix: "[spendings.repo] "),
            offline: DefaultSpendingsOfflineRepository(
                persistency: persistency
            ),
            taskFactory: DefaultTaskFactory()
        )
        friendListRepository = DefaultFriendsRepository(
            api: api,
            longPoll: longPoll,
            logger: .shared.with(prefix: "[friends.repo] "),
            offline: DefaultFriendsOfflineRepository(
                persistency: persistency
            )
        )

        logoutUseCase = await DefaultLogoutUseCase(
            persistency: persistency,
            shouldLogout: logoutSubject.eraseToAnyPublisher()
        )
    }

    func spendingsOfflineRepository() -> SpendingsOfflineRepository {
        DefaultSpendingsOfflineRepository(
            persistency: persistency
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
            repository: profileRepository
        )
    }

    func friendsOfflineRepository() -> FriendsOfflineRepository {
        DefaultFriendsOfflineRepository(
            persistency: persistency
        )
    }

    func profileOfflineRepository() -> ProfileOfflineRepository {
        DefaultProfileOfflineRepository(
            persistency: persistency
        )
    }

    func pushRegistrationUseCase() -> PushRegistrationUseCase {
        DefaultPushRegistrationUseCase(
            api: api, 
            logger: .shared.with(prefix: "[push] ")
        )
    }

    func usersOfflineRepository() -> UsersOfflineRepository {
        DefaultUsersOfflineRepository(
            persistency: persistency
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
