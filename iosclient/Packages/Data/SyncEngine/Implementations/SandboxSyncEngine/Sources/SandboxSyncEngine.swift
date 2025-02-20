import SyncEngine
import Api
import Logging
import PersistentStorage
import AsyncExtensions

actor SandboxSyncEngine {
    let logger: Logger
    private let storage: SandboxStorage
    private let eventPublisher: EventPublisher<[Components.Schemas.SomeOperation]>

    init(
        storage: SandboxStorage,
        taskFactory: TaskFactory,
        logger: Logger
    ) async {
        self.storage = storage
        self.logger = logger
        self.eventPublisher = EventPublisher()
    }
}

extension SandboxSyncEngine: Engine {
    var operations: [Components.Schemas.SomeOperation] {
        get async {
            await storage.operations
        }
    }
    
    var updates: any EventSource<[Components.Schemas.SomeOperation]> {
        eventPublisher
    }
    
    func push(operations: [Components.Schemas.SomeOperation]) async throws {
        try await storage
            .update(operations: operations)
        await eventPublisher
            .notify(operations)
    }
}

extension SandboxSyncEngine: Loggable {}
