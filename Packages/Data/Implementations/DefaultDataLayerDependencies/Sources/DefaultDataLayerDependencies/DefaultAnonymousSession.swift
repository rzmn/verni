import Api
import DataTransferObjects
import PersistentStorage
import Foundation
import AsyncExtensions
import DataLayerDependencies
import Logging
import Infrastructure
internal import Base
internal import DefaultNetworkingImplementation
internal import DefaultApiServiceImplementation
internal import DefaultApiImplementation
internal import PersistentStorageSQLite

struct Constants {
    static let apiEndpoint = "http://193.124.113.41:8082"
    static let appId = "com.rzmn.accountydev.app"
    static let appGroup = "group.\(appId)"
}

public final class DefaultAnonymousSession: AnonymousDataLayerSession {
    public let authenticator: AuthenticatedDataLayerSessionFactory
    public let api: ApiProtocol

    public init(logger: Logger, infrastructure: InfrastructureLayer) throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        let networkServiceFactory = DefaultNetworkServiceFactory(
            logger: logger.with(
                prefix: "↔️"
            ),
            session: .shared,
            endpoint: Endpoint(
                path: Constants.apiEndpoint
            )
        )
        let apiServiceFactory = DefaultApiServiceFactory(
            logger: logger.with(
                prefix: "⚡️"
            ),
            networkServiceFactory: networkServiceFactory,
            taskFactory: infrastructure.taskFactory
        )
        api = DefaultApiFactory(
            service: apiServiceFactory.create(tokenRefresher: nil),
            taskFactory: infrastructure.taskFactory,
            logger: logger
        ).create()
        authenticator = DefaultAuthenticatedSessionFactory(
            api: api,
            taskFactory: infrastructure.taskFactory,
            logger: logger,
            apiServiceFactory: apiServiceFactory,
            persistencyFactory: try SQLitePersistencyFactory(
                logger: logger.with(
                    prefix: "🗄️"
                ),
                dbDirectory: permanentCacheDirectory,
                taskFactory: infrastructure.taskFactory,
                fileManager: infrastructure.fileManager
            )
        )
    }
}
