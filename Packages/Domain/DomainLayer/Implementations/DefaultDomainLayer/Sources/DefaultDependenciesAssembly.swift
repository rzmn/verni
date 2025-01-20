import Foundation
import AsyncExtensions
internal import DefaultInfrastructure
internal import Logging
internal import DataLayerDependencies
internal import DefaultDataLayerDependencies
internal import Base
internal import DefaultAuthUseCaseImplementation
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultSaveCredendialsUseCaseImplementation

public final class DefaultDependenciesAssembly: AnonymousDomainLayerSession, Sendable {
    private let dataLayer: AnonymousDataLayerSession
    private let avatarsRepository: AvatarsRepository
    private let webcredentials = "https://verni.app"
    public let appCommon: AppCommon

    let infrastructure = DefaultInfrastructureLayer()
    let avatarsOfflineMutableRepository: AvatarsOfflineMutableRepository

    public init() throws {
        let logger = infrastructure.logger.with(prefix: "👷‍♀️")
        dataLayer = try DefaultAnonymousSession(
            logger: logger,
            infrastructure: infrastructure
        )
        guard let temporaryCacheDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        let avatarsLogger = logger.with(
            prefix: "🌄"
        )
        let avatarsOfflineRepository = try DefaultAvatarsOfflineRepository(
            container: temporaryCacheDirectory,
            logger: avatarsLogger.with(prefix: "💾")
        )
        avatarsOfflineMutableRepository = avatarsOfflineRepository
        avatarsRepository = DefaultAvatarsRepository(
            api: dataLayer.api,
            taskFactory: infrastructure.taskFactory,
            offlineRepository: avatarsOfflineRepository,
            offlineMutableRepository: avatarsOfflineRepository,
            logger: avatarsLogger
        )
        appCommon = AppCommonDependencies(
            api: dataLayer.api,
            avatarsRepository: avatarsRepository,
            saveCredentialsUseCase: DefaultSaveCredendialsUseCase(
                website: webcredentials,
                logger: logger.with(
                    prefix: "🔐"
                )
            ),
            infrastructure: infrastructure
        )
    }

    public func authUseCase() -> any AuthUseCase<AuthenticatedDomainLayerSession> {
        AuthUseCaseAdapter(
            impl: DefaultAuthUseCase(
                taskFactory: infrastructure.taskFactory,
                dataLayer: dataLayer
            ), dependencies: self
        )
    }
}
