import Api
import PersistentStorage
import Foundation
import AsyncExtensions
import DataLayerDependencies
import Logging
import Infrastructure
internal import Base
internal import DefaultApiImplementation
internal import PersistentStorageSQLite

struct Constants {
    static let apiEndpoint = URL(string: "http://193.124.113.41:8082")!
    static let appId = "com.rzmn.accountydev.app"
    static let appGroup = "group.\(appId)"
}

public final class DefaultAnonymousSession: AnonymousDataLayerSession {
    public let storage: SandboxStorage
    public let authenticator: AuthenticatedDataLayerSessionFactory
    public let api: APIProtocol

    public init(logger: Logger, infrastructure: InfrastructureLayer) throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        api = DefaultApiFactory(
            url: Constants.apiEndpoint,
            taskFactory: infrastructure.taskFactory,
            logger: logger,
            tokenRepository: nil
        ).create()
        let storageFactory = try SQLiteStorageFactory(
            logger: logger.with(
                prefix: "🗄️"
            ),
            dbDirectory: permanentCacheDirectory,
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        storage = try storageFactory.sandbox()
        authenticator = DefaultAuthenticatedSessionFactory(
            api: api,
            taskFactory: infrastructure.taskFactory,
            logger: logger,
            persistencyFactory: storageFactory
        )
    }
}
