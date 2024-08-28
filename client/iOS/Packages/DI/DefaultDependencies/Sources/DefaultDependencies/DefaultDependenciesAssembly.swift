import DI
import Domain
import Foundation
internal import AuthSession
internal import Api
internal import ApiService
internal import DefaultApiImplementation
internal import Networking
internal import PersistentStorage
internal import DefaultAuthUseCaseImplementation
internal import DefaultApiServiceImplementation
internal import DefaultNetworkingImplementation
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultSaveCredendialsUseCaseImplementation
internal import PersistentStorageSQLite

fileprivate class AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
    private let impl: any AuthUseCase
    private let awakeHook: () async -> Result<any DI.ActiveSessionDIContainer, AwakeError>
    private let loginHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, LoginError>
    private let signupHook: (Domain.Credentials) async -> Result<any DI.ActiveSessionDIContainer, SignupError>

    init<Impl: AuthUseCase>(impl: Impl) where Impl.AuthorizedSession == any ActiveSessionDIContainerConvertible {
        self.impl = impl
        awakeHook = {
            await impl.awake().map {
                $0.activeSessionDIContainer as ActiveSessionDIContainer
            }
        }
        loginHook = {
            await impl.login(credentials: $0).map {
                $0.activeSessionDIContainer as ActiveSessionDIContainer
            }
        }
        signupHook = {
            await impl.signup(credentials: $0).map {
                $0.activeSessionDIContainer as ActiveSessionDIContainer
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
}


public class DefaultDependenciesAssembly: DIContainer {    
    private lazy var anonymousApi = anonymousApiFactory().create()
    private lazy var avatarsRepository = DefaultAvatarsRepository(api: anonymousApi)
    private let apiEndpoint = "http://193.124.113.41:8082"
    private let webcredentials = "https://d5d29sfljfs1v5kq0382.apigw.yandexcloud.net"

    public init() {}

    public lazy var appCommon: AppCommon = AppCommonDependencies(
        api: anonymousApi,
        avatarsRepository: avatarsRepository,
        saveCredentialsUseCase: DefaultSaveCredendialsUseCase(
            website: webcredentials
        )
    )

    public func authUseCase() -> any AuthUseCaseReturningActiveSession {
        AuthUseCaseAdapter(
            impl: DefaultAuthUseCase(
                api: anonymousApi,
                apiServiceFactory: apiServiceFactory(), 
                persistencyFactory: persistencyFactory(), 
                activeSessionDIContainerFactory: ActiveSessionDependenciesAssemblyFactory(
                    appCommon: appCommon
                ),
                apiFactoryProvider: self.autenticatedApiFactory
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
            session: .shared,
            endpoint: Endpoint(
                path: apiEndpoint
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

    func anonymousApiFactory() -> ApiFactory {
        DefaultApiFactory(service: apiServiceFactory().create(tokenRefresher: nil))
    }

    func autenticatedApiFactory(refresher: TokenRefresher) -> ApiFactory {
        DefaultApiFactory(service: apiServiceFactory().create(tokenRefresher: refresher))
    }

    func persistencyFactory() -> PersistencyFactory {
        SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[db] "),
            appFolder: FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.rzmn.accountydev.app"
            ).unsafelyUnwrapped
        )
    }
}
