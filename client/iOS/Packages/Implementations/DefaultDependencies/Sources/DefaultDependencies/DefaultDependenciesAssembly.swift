import DI
import Domain
internal import AuthSession
internal import Api
internal import ApiService
internal import Networking
internal import DefaultAuthUseCaseImplementation
internal import DefaultApiServiceImplementation
internal import DefaultNetworkingImplementation
internal import DefaultAuthorizedSessionRepositoryImplementation
internal import DefaultFriendsRepositoryImplementation
internal import DefaultFriendInteractionsUseCaseImplementation
internal import DefaultQRInviteUseCaseImplementation

extension ActiveSession: ActiveSessionDIContainer, LogoutUseCase {
    public func logout() async {
        invalidate()
    }

    public func logoutUseCase() -> any LogoutUseCase {
        self
    }

    public func friendListRepository() -> FriendsRepository {
        DefaultFriendsRepository(api: api)
    }
    
    public func usersRepository() -> UsersRepository {
        DefaultAuthorizedSessionRepository(api: api)
    }
    
    public func friendInterationsUseCase() -> FriendInteractionsUseCase {
        DefaultFriendInteractionsUseCase(api: api)
    }

    public func qrInviteUseCase() -> any QRInviteUseCase {
        DefaultQRInviteUseCase()
    }
}

fileprivate class AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
    private let impl: any AuthUseCase
    private let awakeHook: () async -> Result<any DI.ActiveSessionDIContainer, AwakeFailureReason>
    private let loginHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, LoginFailureReason>
    private let signupHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, SignupFailureReason>

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

    func awake() async -> Result<any ActiveSessionDIContainer, AwakeFailureReason> {
        await awakeHook()
    }

    func login(credentials: Credentials) async -> Result<any ActiveSessionDIContainer, LoginFailureReason> {
        await loginHook(credentials)
    }

    func signup(credentials: Credentials) async -> Result<any ActiveSessionDIContainer, SignupFailureReason> {
        await signupHook(credentials)
    }

    func validateLogin(_ login: String) async -> Result<Void, ValidationFailureReason> {
        await impl.validateLogin(login)
    }

    func validatePassword(_ password: String) async -> Result<Void, ValidationFailureReason> {
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
                apiServiceFactory: apiServiceFactory()
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
                path: "https://sharedexpenses.containers.cloud.ru"
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
}

