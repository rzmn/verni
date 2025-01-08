import PersistentStorage
import Api
import Logging
internal import SQLite

@StorageActor final class MustInitSandboxStorage {
    private var _impl: SandboxStorage?
    private var impl: SandboxStorage {
        get async {
            let value: SandboxStorage
            if let existed = _impl {
                value = existed
            } else {
                value = try! await implInit()
            }
            return value
        }
    }
    private let implInit: @Sendable () async throws -> SandboxStorage
    
    nonisolated init(implInit: @escaping @Sendable () async throws -> SandboxStorage) {
        self.implInit = implInit
    }
}

@StorageActor extension MustInitSandboxStorage: SandboxStorage {
    var operations: [Api.Components.Schemas.Operation] {
        get async {
            await impl.operations
        }
    }
    
    func update(operations: [Components.Schemas.Operation]) async throws {
        try await impl.update(operations: operations)
    }
    
    func close() async {
        await impl.close()
    }
    
    func invalidate() async {
        await impl.invalidate()
    }
}

@StorageActor final class SQLiteSandboxStorage {
    let logger: Logger
    let connection: SQLiteConnectionHolder
    private(set) var operations: [Components.Schemas.Operation]
    
    init(
        logger: Logger,
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void
    ) throws {
        self.logger = logger
        self.connection = SQLiteConnectionHolder(
            logger: logger,
            database: database,
            invalidator: invalidator
        )
        self.operations = try database.getOperations()
    }
}

extension SQLiteSandboxStorage: SandboxStorage {
    func update(operations: [Components.Schemas.Operation]) async throws {
        guard let database = connection.database else {
            return
        }
        try database.update(operations: operations)
        self.operations = operations.merged(with: self.operations).all
    }
    
    func close() async {
        connection.close()
    }
    
    func invalidate() async {
        connection.invalidate()
    }
}

extension SQLiteSandboxStorage: Loggable {}

