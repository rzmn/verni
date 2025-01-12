import Api
import PersistentStorage
import Foundation
import AsyncExtensions
import DataLayer
import Logging
import InfrastructureLayer
import SyncEngine
internal import SandboxSyncEngine
internal import Convenience
internal import DefaultApiImplementation
internal import PersistentStorageSQLite

struct Constants {
    static let apiEndpoint = URL(string: "http://193.124.113.41:8082")!
    static let appId = "com.rzmn.accountydev.app"
    static let appGroup = "group.\(appId)"
}

public final class DefaultAnonymousSession: AnonymousDataLayerSession {
    public let storage: SandboxStorage
    private let syncEngineFactory: EngineFactory
    private let _sync: AsyncLazyObject<Engine>
    public var sync: Engine {
        get async {
            await _sync.value
        }
    }
    public let authenticator: AuthenticatedDataLayerSessionFactory
    public let api: APIProtocol
    public let infrastructure: InfrastructureLayer

    public init(
        logger: Logger,
        infrastructure: InfrastructureLayer
    ) throws {
        guard let permanentCacheDirectory = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup
        ) else {
            throw InternalError.error("cannot get required directories for data storage", underlying: nil)
        }
        self.infrastructure = infrastructure
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
        let syncEngineFactory = SandboxSyncEngineFactory(
            storage: storage,
            taskFactory: infrastructure.taskFactory,
            logger: logger.with(
                prefix: "🔄"
            )
        )
        self.syncEngineFactory = syncEngineFactory
        _sync = AsyncLazyObject {
            await syncEngineFactory.create()
        }
        authenticator = DefaultAuthenticatedSessionFactory(
            api: api,
            taskFactory: infrastructure.taskFactory,
            logger: logger,
            persistencyFactory: storageFactory
        )
    }
}
