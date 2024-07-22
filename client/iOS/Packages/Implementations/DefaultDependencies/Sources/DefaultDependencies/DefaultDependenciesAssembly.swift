import DI
import Domain
internal import AuthSession
internal import Api
internal import ApiService
internal import Networking
internal import PersistentStorage
internal import DefaultAuthUseCaseImplementation
internal import DefaultApiServiceImplementation
internal import DefaultNetworkingImplementation
internal import DefaultUsersRepositoryImplementation
internal import DefaultFriendsRepositoryImplementation
internal import DefaultFriendInteractionsUseCaseImplementation
internal import DefaultQRInviteUseCaseImplementation
internal import DefaultSpendingInteractionsUseCaseImplementation
internal import DefaultSpendingsRepositoryImplementation
internal import DefaultPersistentStorageImplementation

extension ActiveSession: ActiveSessionDIContainer, LogoutUseCase {
    public func logout() async {
        invalidate()
    }

    public func logoutUseCase() -> any LogoutUseCase {
        self
    }

    public func friendListRepository() -> FriendsRepository {
        DefaultFriendsRepository(api: api, persistency: persistency)
    }

    public func friendsOfflineRepository() -> FriendsOfflineRepository {
        DefaultFriendsOfflineRepository(persistency: persistency)
    }

    public func usersRepository() -> UsersRepository {
        DefaultUsersRepository(api: api, persistency: persistency)
    }

    public func friendInterationsUseCase() -> FriendInteractionsUseCase {
        DefaultFriendInteractionsUseCase(api: api)
    }

    public func qrInviteUseCase() -> QRInviteUseCase {
        DefaultQRInviteUseCase()
    }

    public func spendingsRepository() -> SpendingsRepository {
        DefaultSpendingsRepository(api: api, persistency: persistency)
    }

    public func spendingsOfflineRepository() -> SpendingsOfflineRepository {
        DefaultSpendingsOfflineRepository(persistency: persistency)
    }

    public func spendingInteractionsUseCase() -> SpendingInteractionsUseCase {
        DefaultSpendingInteractionsUseCase(api: api)
    }

    public func usersOfflineRepository() -> UsersOfflineRepository {
        DefaultUsersOfflineRepository(persistency: persistency)
    }
}

fileprivate class AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
    private let impl: any AuthUseCase
    private let awakeHook: () async -> Result<any DI.ActiveSessionDIContainer, AwakeError>
    private let loginHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, LoginError>
    private let signupHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, SignupError>

    init<Impl: AuthUseCase>(impl: Impl) where Impl.AuthorizedSession == ActiveSession {
        self.impl = impl
        awakeHook = {
            await impl.awake().map {
                $0 as ActiveSessionDIContainer
            }
        }
        loginHook = {
            await impl.login(credentials: $0).map {
                $0 as ActiveSessionDIContainer
            }
        }
        signupHook = {
            await impl.signup(credentials: $0).map {
                $0 as ActiveSessionDIContainer
            }
        }
    }

    func awake() async -> Result<any ActiveSessionDIContainer, AwakeError> {
        await awakeHook()
    }

    func login(credentials: Credentials) async -> Result<any ActiveSessionDIContainer, LoginError> {
        await loginHook(credentials)
    }

    func signup(credentials: Credentials) async -> Result<any ActiveSessionDIContainer, SignupError> {
        await signupHook(credentials)
    }

    func validateLogin(_ login: String) async -> Result<Void, CredentialsValidationError> {
        await impl.validateLogin(login)
    }

    func validatePassword(_ password: String) async -> Result<Void, CredentialsValidationError> {
        await impl.validatePassword(password)
    }
}


public class DefaultDependenciesAssembly: DIContainer {
    private lazy var anonymousApi = Api(service: apiServiceFactory().create(tokenRefresher: nil))

    public init() {}

    public func authUseCase() -> any AuthUseCaseReturningActiveSession {
        AuthUseCaseAdapter(
            impl: DefaultAuthUseCase(
                api: anonymousApi,
                apiServiceFactory: apiServiceFactory(), 
                persistencyFactory: persistencyFactory()
            )
        )
    }
}

extension DefaultDependenciesAssembly {
    func networkServiceFactory() -> NetworkServiceFactory {
        DefaultNetworkServiceFactory(
            logger: .shared.with(
                prefix: "[net] "
            ),
            endpoint: Endpoint(
                path: "https://d5d29sfljfs1v5kq0382.apigw.yandexcloud.net"
            )
        )
    }

    func apiServiceFactory() -> ApiServiceFactory {
        DefaultApiServiceFactory(
            logger: .shared.with(
                prefix: "[api.s] "
            ),
            networkServiceFactory: networkServiceFactory()
        )
    }

    func persistencyFactory() -> PersistencyFactory {
        DefaultPersistencyFactory(logger: .shared.with(prefix: "[db]"))
    }
}

