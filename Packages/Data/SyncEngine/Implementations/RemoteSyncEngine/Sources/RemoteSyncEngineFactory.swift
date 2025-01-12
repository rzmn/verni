import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

public final class RemoteSyncEngineFactory: Sendable {
    private let storage: UserStorage
    private let taskFactory: TaskFactory
    private let logger: Logger
    private let api: APIProtocol
    
    public init(
        api: APIProtocol,
        storage: UserStorage,
        taskFactory: TaskFactory,
        logger: Logger
    ) {
        self.api = api
        self.storage = storage
        self.taskFactory = taskFactory
        self.logger = logger
    }
}

extension RemoteSyncEngineFactory: EngineFactory {
    public func create() async -> Engine {
        await RemoteSyncEngine(
            api: api,
            storage: storage,
            logger: logger,
            taskFactory: taskFactory
        )
    }
}
