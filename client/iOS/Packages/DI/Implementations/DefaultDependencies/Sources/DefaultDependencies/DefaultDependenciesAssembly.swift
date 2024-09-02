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

fileprivate actor AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
    private let impl: any AuthUseCase
    private let awakeHook: () async throws(AwakeError) -> any ActiveSessionDIContainer
    private let loginHook: (Credentials) async throws(LoginError) -> any ActiveSessionDIContainer
    private let signupHook: (Credentials) async throws(SignupError) -> any ActiveSessionDIContainer

    init<Impl: AuthUseCase>(impl: Impl) where Impl.AuthorizedSession == any ActiveSessionDIContainerConvertible {
        self.impl = impl
        awakeHook = { () async throws(AwakeError) -> any ActiveSessionDIContainer in
            try await impl.awake().activeSessionDIContainer()
        }
        loginHook = { credentials async throws(LoginError) -> any ActiveSessionDIContainer in
            try await impl.login(credentials: credentials).activeSessionDIContainer()
        }
        signupHook = { credentials async throws(SignupError) -> any ActiveSessionDIContainer in
            try await impl.signup(credentials: credentials).activeSessionDIContainer()
        }
    }

    func awake() async throws(AwakeError) -> any ActiveSessionDIContainer {
        try await awakeHook()
    }

    func login(credentials: Credentials) async throws(LoginError) -> any ActiveSessionDIContainer {
        try await loginHook(credentials)
    }

    func signup(credentials: Credentials) async throws(SignupError) -> any ActiveSessionDIContainer {
        try await signupHook(credentials)
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
