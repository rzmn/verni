import Foundation
import Logging
import PersistentStorage
import Domain
internal import DataTransferObjects
internal import SQLite

@globalActor public actor StorageActor: GlobalActor {
    public static let shared = StorageActor()
}

public class DefaultPersistencyFactory {
    public let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }
}

extension DefaultPersistencyFactory: PersistencyFactory {
    @StorageActor public func awake() -> Persistency? {
        logI { "awaking persistence..." }
        let dbUrl: URL
        do {
            let dbDirectory = DbNameBuilder.shared.dbDirectory
            try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
            let contents = try FileManager.default
                .contentsOfDirectory(at: dbDirectory, includingPropertiesForKeys: nil)
                .filter { $0.isFileURL && DbNameBuilder.shared.isDbName($0.lastPathComponent) }
            if contents.isEmpty {
                logI { "has no persistence" }
                return nil
            }
            dbUrl = contents[0]
        } catch {
            logE { "got error searching for db path error: \(error)" }
            return nil
        }
        guard let hostId = DbNameBuilder.shared.dbOwnerId(dbUrl.lastPathComponent) else {
            logI { "url is not recognized as valid db url \(dbUrl)" }
            return nil
        }
        logI { "found db url: \(dbUrl)" }
        do {
            let db = try Connection(dbUrl.absoluteString)
            let token = try db.prepare(Schema.Tokens.table)
                .first { row in
                    try row.get(Schema.Tokens.Keys.id) == hostId
                }?
                .get(Schema.Tokens.Keys.token)
            guard let token else {
                logger.logE { "db does not have host/credentials info" }
                return nil
            }
            return DefaultPersistency(
                db: db,
                dbInvalidationHandler: {
                    try FileManager.default.removeItem(at: dbUrl)
                },
                hostId: hostId,
                refreshToken: token,
                logger: logger
            )
        } catch {
            logE { "failed to create db from url due error: \(error)" }
            return nil
        }
    }
    
    @StorageActor public func create(hostId: User.ID, refreshToken: String) throws -> Persistency {
        logI { "creating persistence..." }
        let dbUrl = DbNameBuilder.shared.dbDirectory
            .appending(component: DbNameBuilder.shared.dbName(owner: hostId))
        let db = try Connection(dbUrl.absoluteString)
        do {
            try createTables(for: db)
        } catch {
            try FileManager.default.removeItem(at: dbUrl)
            throw error
        }
        return DefaultPersistency(
            db: db, 
            dbInvalidationHandler: {
                try FileManager.default.removeItem(at: dbUrl)
            },
            hostId: hostId,
            refreshToken: refreshToken,
            logger: logger,
            storeInitialToken: true
        )
    }

    @StorageActor private func createTables(for db: Connection) throws {
        try db.run(Schema.Tokens.table.create { t in
            t.column(Schema.Tokens.Keys.id, primaryKey: true)
            t.column(Schema.Tokens.Keys.token)
        })
        try db.run(Schema.Users.table.create { t in
            t.column(Schema.Users.Keys.id, primaryKey: true)
            t.column(Schema.Users.Keys.payload)
        })
        try db.run(Schema.Friends.table.create { t in
            t.column(Schema.Friends.Keys.id, primaryKey: true)
            t.column(Schema.Friends.Keys.payload)
        })
        try db.run(Schema.SpendingsHistory.table.create { t in
            t.column(Schema.SpendingsHistory.Keys.id, primaryKey: true)
            t.column(Schema.SpendingsHistory.Keys.payload)
        })
        try db.run(Schema.SpendingCounterparties.table.create { t in
            t.column(Schema.SpendingCounterparties.Keys.id, primaryKey: true)
            t.column(Schema.SpendingCounterparties.Keys.payload)
        })
    }
}

private extension DefaultPersistencyFactory {
    struct DbNameBuilder {
        public static let shared = DbNameBuilder()
        private var prefix: String { "s_v1_" }
        private var suffix: String { ".sqlite" }

        func isDbName(_ filename: String) -> Bool {
            filename.hasPrefix(prefix) && filename.hasSuffix(suffix) && filename != prefix
        }

        func dbOwnerId(_ filename: String) -> String? {
            guard isDbName(filename) else {
                return nil
            }
            return String(filename.suffix(filename.count - prefix.count).prefix(filename.count - prefix.count - suffix.count))
        }

        func dbName(owner: String) -> String {
            "\(prefix)\(owner)\(suffix)"
        }

        var dbDirectory: URL {
            URL.documentsDirectory.appending(component: "accounty_db")
        }
    }
}

extension DefaultPersistencyFactory: Loggable {}
