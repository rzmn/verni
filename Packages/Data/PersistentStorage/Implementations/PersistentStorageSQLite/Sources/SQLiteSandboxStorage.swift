import PersistentStorage
import Api
import Logging
internal import SQLite

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
        try database.update(
            operations: operations
        )
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

