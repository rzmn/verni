import DI
import Domain
import Foundation
import AsyncExtensions
internal import DataLayerDependencies
internal import DefaultDataLayerDependencies
internal import Base
internal import DefaultAuthUseCaseImplementation
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultSaveCredendialsUseCaseImplementation

private actor AuthUseCaseAdapter: AuthUseCaseReturningActiveSession {
    private let impl: any AuthUseCase
    private let awakeHook: () async throws(AwakeError) -> any ActiveSessionDIContainer
    private let loginHook: (Credentials) async throws(LoginError) -> any ActiveSessionDIContainer
    private let signupHook: (Credentials) async throws(SignupError) -> any ActiveSessionDIContainer

    init<Impl: AuthUseCase>(
        impl: Impl,
        dependencies: DefaultDependenciesAssembly
    ) where Impl.AuthorizedSession == any AuthenticatedDataLayerSession {
        self.impl = impl
        awakeHook = { () async throws(AwakeError) -> any ActiveSessionDIContainer in
            await ActiveSessionDependenciesAssembly(
                defaultDependencies: dependencies,
                dataLayer: try await impl.awake()
            )
        }
        loginHook = { credentials async throws(LoginError) -> any ActiveSessionDIContainer in
            await ActiveSessionDependenciesAssembly(
                defaultDependencies: dependencies,
                dataLayer: try await impl.login(credentials: credentials)
            )
        }
        signupHook = { credentials async throws(SignupError) -> any ActiveSessionDIContainer in
            await ActiveSessionDependenciesAssembly(
                defaultDependencies: dependencies,
                dataLayer: try await impl.signup(credentials: credentials)
            )
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
    private let dataLayer: AnonymousDataLayerSession
    private let avatarsRepository: AvatarsRepository
    private let webcredentials = "https://d5d29sfljfs1v5kq0382.apigw.yandexcloud.net"
    private let taskFactory = DefaultTaskFactory()

    let avatarsOfflineMutableRepository: AvatarsOfflineMutableRepository
    public let appCommon: AppCommon

    public init() async throws {
        dataLayer = try await DefaultAnonymousDataLayerSession(taskFactory: taskFactory)
        guard let temporaryCacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }

        let avatarsOfflineRepository = try DefaultAvatarsOfflineRepository(
            container: temporaryCacheDirectory,
            logger: .shared.with(prefix: "[avatars.offline] ")
        )
        avatarsOfflineMutableRepository = avatarsOfflineRepository
        avatarsRepository = DefaultAvatarsRepository(
            api: dataLayer.api,
            taskFactory: DefaultTaskFactory(),
            offlineRepository: avatarsOfflineRepository,
            offlineMutableRepository: avatarsOfflineRepository,
            logger: .shared.with(prefix: "[avatars] ")
        )
        appCommon = AppCommonDependencies(
            api: dataLayer.api,
            avatarsRepository: avatarsRepository,
            saveCredentialsUseCase: DefaultSaveCredendialsUseCase(
                website: webcredentials,
                logger: .shared.with(prefix: "[credentials.save] ")
            )
        )
    }

    public func authUseCase() async -> any AuthUseCaseReturningActiveSession {
        AuthUseCaseAdapter(
            impl: await DefaultAuthUseCase(
                taskFactory: DefaultTaskFactory(),
                dataLayer: dataLayer
            ), dependencies: self
        )
    }
}
