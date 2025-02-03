import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

actor SandboxSyncEngine {
    let logger: Logger
    private let storage: SandboxStorage
    private let updatesSubject: AsyncSubject<[Components.Schemas.SomeOperation]>

    init(
        storage: SandboxStorage,
        taskFactory: TaskFactory,
        logger: Logger
    ) async {
        self.storage = storage
        self.logger = logger
        self.updatesSubject = AsyncSubject(
            taskFactory: taskFactory,
            logger: logger
        )
    }
}

extension SandboxSyncEngine: Engine {
    var operations: [Api.Components.Schemas.SomeOperation] {
        get async {
            await storage.operations
        }
    }
    
    var updates: any AsyncBroadcast<[Components.Schemas.SomeOperation]> {
        get async {
            updatesSubject
        }
    }
    
    func push(operations: [Components.Schemas.SomeOperation]) async throws {
        try await storage
            .update(operations: operations)
    }
    
    func pulled(operations: [Components.Schemas.SomeOperation]) async throws {
        try await storage
            .update(operations: operations)
    }
}

extension SandboxSyncEngine: Loggable {}
