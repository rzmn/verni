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

public final class SandboxDataSession: DataSession {
    private let syncEngineFactory: EngineFactory
    private let _sync: AsyncLazyObject<Engine>
    public var sync: Engine {
        get async {
            await _sync.value
        }
    }
    public let api: APIProtocol

    nonisolated public init(
        storageFactory: StorageFactory,
        logger: Logger,
        infrastructure: InfrastructureLayer
    ) {
        api = DefaultApiFactory(
            url: Constants.apiEndpoint,
            taskFactory: infrastructure.taskFactory,
            logger: logger,
            tokenRepository: nil
        ).create()
        let syncEngineFactory = SandboxSyncEngineFactory(
            storage: storageFactory.sandbox,
            taskFactory: infrastructure.taskFactory,
            logger: logger.with(
                prefix: "🔄"
            )
        )
        self.syncEngineFactory = syncEngineFactory
        _sync = AsyncLazyObject {
            await syncEngineFactory.create()
        }
    }
    
    public func suspend() async {
        assertionFailure("not implemented")
    }
}
