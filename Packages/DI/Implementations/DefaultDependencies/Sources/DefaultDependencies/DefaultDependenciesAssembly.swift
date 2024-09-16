import DI
import Domain
import Foundation
import AsyncExtensions
internal import Base
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

private actor AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
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

public final class DefaultDependenciesAssembly: DIContainer, Sendable {
    private let anonymousApi: ApiProtocol
    private let apiServiceFactory: ApiServiceFactory
    private let networkServiceFactory: NetworkServiceFactory
    private let avatarsRepository: AvatarsRepository
    private let apiEndpoint = "http://193.124.113.41:8082"
    private let webcredentials = "https://d5d29sfljfs1v5kq0382.apigw.yandexcloud.net"
    private let taskFactory = DefaultTaskFactory()
    private let persistencyFactory: PersistencyFactory

    let avatarsOfflineMutableRepository: AvatarsOfflineMutableRepository
    public let appCommon: AppCommon

    public init() async throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.rzmn.accountydev.app"
        ), let temporaryCacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        networkServiceFactory = DefaultNetworkServiceFactory(
            logger: .shared.with(
                prefix: "[net] "
            ),
            session: .shared,
            endpoint: Endpoint(
                path: apiEndpoint
            )
        )
        apiServiceFactory = DefaultApiServiceFactory(
            logger: .shared.with(
                prefix: "[api.s] "
            ),
            networkServiceFactory: networkServiceFactory,
            taskFactory: taskFactory
        )
        let apiFactory = await DefaultApiFactory(
            service: apiServiceFactory.create(tokenRefresher: nil),
            taskFactory: taskFactory
        )
        persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[db] "),
            dbDirectory: permanentCacheDirectory,
            taskFactory: taskFactory
        )
        anonymousApi = apiFactory.create()
        let avatarsOfflineRepository = try DefaultAvatarsOfflineRepository(
            container: temporaryCacheDirectory,
            logger: .shared.with(prefix: "[avatars.offline] ")
        )
        avatarsOfflineMutableRepository = avatarsOfflineRepository
        avatarsRepository = DefaultAvatarsRepository(
            api: anonymousApi,
            taskFactory: DefaultTaskFactory(),
            offlineRepository: avatarsOfflineRepository,
            offlineMutableRepository: avatarsOfflineRepository,
            logger: .shared.with(prefix: "avatars")
        )
        appCommon = AppCommonDependencies(
            api: anonymousApi,
            avatarsRepository: avatarsRepository,
            saveCredentialsUseCase: DefaultSaveCredendialsUseCase(
                website: webcredentials
            )
        )
    }

    public func authUseCase() async -> any AuthUseCaseReturningActiveSession {
        AuthUseCaseAdapter(
            impl: await DefaultAuthUseCase(
                api: anonymousApi,
                apiServiceFactory: apiServiceFactory,
                persistencyFactory: persistencyFactory,
                activeSessionDIContainerFactory: ActiveSessionDependenciesAssemblyFactory(
                    defaultDependencies: self
                ),
                apiFactoryProvider: { refresher in
                    await DefaultApiFactory(
                        service: self.apiServiceFactory.create(
                            tokenRefresher: refresher
                        ),
                        taskFactory: self.taskFactory
                    )
                }
            )
        )
    }
}
