import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

public final class SandboxSyncEngineFactory: Sendable {
    private let storage: SandboxStorage
    private let taskFactory: TaskFactory
    private let logger: Logger
    
    public init(
        storage: SandboxStorage,
        taskFactory: TaskFactory,
        logger: Logger
    ) {
        self.storage = storage
        self.taskFactory = taskFactory
        self.logger = logger
    }
}

extension SandboxSyncEngineFactory: EngineFactory {
    public func create() async -> Engine {
        await SandboxSyncEngine(
            storage: storage,
            taskFactory: taskFactory,
            logger: logger
        )
    }
}
