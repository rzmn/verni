import PersistentStorage
import Logging
internal import SQLite

@StorageActor final class SQLiteConnectionHolder {
    let logger: Logger
    private(set) var database: Connection?
    private let invalidator: @StorageActor @Sendable () -> Void
    
    init(
        logger: Logger,
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void
    ) {
        self.logger = logger
        self.database = database
        self.invalidator = invalidator
    }
}

extension SQLiteConnectionHolder: Storage {    
    func close() {
        database = nil
    }

    func invalidate() {
        logI { "invalidating db..." }
        close()
        invalidator()
    }
}

extension SQLiteConnectionHolder: Loggable {}
