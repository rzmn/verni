import PersistentStorage
import Api
import Logging
internal import SQLite

@StorageActor final class SQLiteSandboxStorage {
    let logger: Logger
    let connection: SqliteConnectionHolder
    private(set) var operations: [Components.Schemas.SomeOperation]
    
    init(
        logger: Logger,
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void
    ) throws {
        self.logger = logger
        self.connection = SqliteConnectionHolder(
            logger: logger,
            database: database,
            invalidator: invalidator
        )
        self.operations = try database.getOperations()
    }
}

extension SQLiteSandboxStorage: SandboxStorage {
    func update(operations: [Components.Schemas.SomeOperation]) async throws {
        guard let database = connection.database else {
            return
        }
        try database.upsert(
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

