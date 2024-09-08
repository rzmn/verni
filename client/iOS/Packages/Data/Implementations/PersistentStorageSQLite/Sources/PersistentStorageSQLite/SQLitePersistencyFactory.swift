import Foundation
import Logging
import PersistentStorage
import DataTransferObjects
import Base
internal import SQLite

public actor SQLitePersistencyFactory {
    public let logger: Logger
    let dbDirectory: URL
    private let pathManager: DBPathManager
    private let taskFactory: TaskFactory

    public init(logger: Logger, dbDirectory: URL, taskFactory: TaskFactory) throws {
        self.logger = logger
        self.dbDirectory = dbDirectory
        self.taskFactory = taskFactory
        self.pathManager = try DBPathManager(container: dbDirectory)
    }
}

extension SQLitePersistencyFactory: PersistencyFactory {
    public func awake(host: UserDto.ID) async -> Persistency? {
        await doAwake(host: host)
    }

    @StorageActor private func doAwake(host: UserDto.ID) async -> Persistency? {
        logI { "awaking persistence..." }
        let dbUrl: URL
        do {
            let dbs = try pathManager.dbs
            guard let descriptor = dbs.first(where: { $0.owner == host }) else {
                logI { "has no persistence for host \(host)" }
                return nil
            }
            dbUrl = descriptor.dbUrl
        } catch {
            logE { "got error searching for db path error: \(error)" }
            return nil
        }
        logI { "found db url: \(dbUrl)" }
        do {
            let db = try Connection(dbUrl.absoluteString)
            let token = try db.prepare(Schema.Tokens.table)
                .first { row in
                    try row.get(Schema.Tokens.Keys.id) == host
                }?
                .get(Schema.Tokens.Keys.token)
            guard let token else {
                logger.logE { "db does not have host/credentials info" }
                return nil
            }
            return SQLitePersistency(
                db: db,
                dbInvalidationHandler: { [pathManager] in
                    try pathManager.invalidate(owner: host)
                },
                hostId: host,
                refreshToken: token,
                logger: logger,
                taskFactory: taskFactory
            )
        } catch {
            logE { "failed to create db from url due error: \(error)" }
            return nil
        }
    }

    public func create(host: UserDto.ID, refreshToken: String) async throws -> Persistency {
        try await doCreate(host: host, refreshToken: refreshToken)
    }

    @StorageActor private func doCreate(host: UserDto.ID, refreshToken: String) async throws -> Persistency {
        logI { "creating persistence..." }
        let dbUrl = try pathManager.create(owner: host).dbUrl
        let db = try Connection(dbUrl.path)
        do {
            try createTables(for: db)
        } catch {
            try FileManager.default.removeItem(at: dbUrl)
            throw error
        }
        return SQLitePersistency(
            db: db,
            dbInvalidationHandler: {
                try FileManager.default.removeItem(at: dbUrl)
            },
            hostId: host,
            refreshToken: refreshToken,
            logger: logger,
            taskFactory: taskFactory,
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
        try db.run(Schema.Profiles.table.create { t in
            t.column(Schema.Profiles.Keys.id, primaryKey: true)
            t.column(Schema.Profiles.Keys.payload)
        })
    }
}

extension SQLitePersistencyFactory: Loggable {}
