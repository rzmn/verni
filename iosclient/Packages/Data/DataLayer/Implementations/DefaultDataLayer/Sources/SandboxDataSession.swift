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
    private actor EngineBox {
        private var _value: Engine?
        private let block: @Sendable () async -> Engine
        var value: Engine {
            get async {
                guard let _value else {
                    let value = await block()
                    _value = value
                    return value
                }
                return _value
            }
        }
        
        init(_ block: @escaping @Sendable () async -> Engine) {
            self.block = block
        }
    }
    
    private let engineBox: EngineBox
    public var sync: Engine {
        get async {
            await engineBox.value
        }
    }
    public let api: APIProtocol

    nonisolated public init(
        storageFactory: StorageFactory,
        infrastructure: InfrastructureLayer
    ) {
        let logger = infrastructure.logger
            .with(scope: .dataLayer(.sandbox))
        api = DefaultApiFactory(
            url: Constants.apiEndpoint,
            taskFactory: infrastructure.taskFactory,
            logger: logger
                .with(scope: .api),
            tokenRepository: nil
        ).create()
        let syncEngineFactory = SandboxSyncEngineFactory(
            storage: storageFactory.sandbox,
            taskFactory: infrastructure.taskFactory,
            logger: logger.with(
                scope: .sync
            )
        )
        engineBox = EngineBox {
            await syncEngineFactory.create()
        }
    }    
}
