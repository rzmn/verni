import Foundation
import Logging
import PersistentStorage
import DataTransferObjects
import Base
import AsyncExtensions
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
    public func awake(host: UserDto.Identifier) async -> Persistency? {
        await doAwake(host: host)
    }

    @StorageActor private func doAwake(host: UserDto.Identifier) async -> Persistency? {
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
            let database = try Connection(dbUrl.absoluteString)
            let token = try database.prepare(Schema.Tokens.table)
                .first { row in
                    try row.get(Schema.Tokens.Keys.id) == host
                }?
                .get(Schema.Tokens.Keys.token)
            guard let token else {
                logger.logE { "db does not have host/credentials info" }
                return nil
            }
            return SQLitePersistency(
                database: database,
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

    public func create(host: UserDto.Identifier, refreshToken: String) async throws -> Persistency {
        try await doCreate(host: host, refreshToken: refreshToken)
    }

    @StorageActor private func doCreate(host: UserDto.Identifier, refreshToken: String) async throws -> Persistency {
        logI { "creating persistence..." }
        let dbUrl = try pathManager.create(owner: host).dbUrl
        let database = try Connection(dbUrl.path)
        do {
            try createTables(for: database)
        } catch {
            try FileManager.default.removeItem(at: dbUrl)
            throw error
        }
        return SQLitePersistency(
            database: database,
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

    @StorageActor private func createTables(for database: Connection) throws {
        try database.run(Schema.Tokens.table.create { table in
            table.column(Schema.Tokens.Keys.id, primaryKey: true)
            table.column(Schema.Tokens.Keys.token)
        })
        try database.run(Schema.Users.table.create { table in
            table.column(Schema.Users.Keys.id, primaryKey: true)
            table.column(Schema.Users.Keys.payload)
        })
        try database.run(Schema.Friends.table.create { table in
            table.column(Schema.Friends.Keys.id, primaryKey: true)
            table.column(Schema.Friends.Keys.payload)
        })
        try database.run(Schema.SpendingsHistory.table.create { table in
            table.column(Schema.SpendingsHistory.Keys.id, primaryKey: true)
            table.column(Schema.SpendingsHistory.Keys.payload)
        })
        try database.run(Schema.SpendingCounterparties.table.create { table in
            table.column(Schema.SpendingCounterparties.Keys.id, primaryKey: true)
            table.column(Schema.SpendingCounterparties.Keys.payload)
        })
        try database.run(Schema.Profile.table.create { table in
            table.column(Schema.Profile.Keys.id, primaryKey: true)
            table.column(Schema.Profile.Keys.payload)
        })
    }
}

extension SQLitePersistencyFactory: Loggable {}
