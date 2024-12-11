import Foundation
import Logging
import PersistentStorage
import DataTransferObjects
import AsyncExtensions
internal import Base
internal import SQLite

public actor SQLitePersistencyFactory {
    public let logger: Logger
    let dbDirectory: URL
    private let taskFactory: TaskFactory
    private let pathManager: PathManager

    public init(logger: Logger, dbDirectory: URL, taskFactory: TaskFactory) throws {
        try self.init(
            logger: logger,
            dbDirectory: dbDirectory,
            taskFactory: taskFactory,
            pathManager: DefaultPathManager()
        )
    }
    
    init(logger: Logger, dbDirectory: URL, taskFactory: TaskFactory, pathManager: PathManager) throws {
        self.logger = logger
        self.dbDirectory = dbDirectory
        self.taskFactory = taskFactory
        self.pathManager = pathManager
    }
}

extension SQLitePersistencyFactory: PersistencyFactory {
    public func awake(host: UserDto.Identifier) async -> Persistency? {
        await doAwake(host: host)
    }

    @StorageActor private func doAwake(host: UserDto.Identifier) async -> Persistency? {
        logI { "awaking persistence..." }
        let pathManager: any DbPathManager<SqliteDbPathManager.Item>
        do {
            pathManager = try createDatabasePathManager()
        } catch {
            logE { "got error creating db path manager error: \(error)" }
            return nil
        }
        let item: SqliteDbPathManager.Item
        do {
            guard let existed = try pathManager.items.first(where: { $0.id == host }) else {
                logI { "has no persistence for host \(host)" }
                return nil
            }
            item = existed
        } catch {
            logE { "got error searching for db path error: \(error)" }
            return nil
        }
        logI { "found item: \(item)" }
        do {
            return try await SQLitePersistency(
                database: try item.connection(),
                invalidator: {
                    pathManager.invalidate(id: host)
                },
                hostId: host,
                refreshToken: nil,
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
        let pathManager = try createDatabasePathManager()
        let database = try pathManager.create(id: host).connection()
        do {
            try createTables(for: database)
        } catch {
            pathManager.invalidate(id: host)
            throw error
        }
        return try await SQLitePersistency(
            database: database,
            invalidator: {
                pathManager.invalidate(id: host)
            },
            hostId: host,
            refreshToken: refreshToken,
            logger: logger,
            taskFactory: taskFactory
        )
    }
    
    @StorageActor private func createDatabasePathManager() throws -> any DbPathManager<SqliteDbPathManager.Item> {
        try SqliteDbPathManager(
            logger: logger.with(prefix: "📁"),
            containerDirectory: dbDirectory,
            versionLabel: "v1",
            pathManager: pathManager
        )
    }

    @StorageActor private func createTables(for database: Connection) throws {
        try Schema.refreshToken.createTable(database: database)
        try Schema.profile.createTable(database: database)
        try Schema.users.createTable(database: database)
        try Schema.spendingCounterparties.createTable(database: database)
        try Schema.spendingsHistory.createTable(database: database)
        try Schema.friends.createTable(database: database)
    }
}


extension SQLitePersistencyFactory: Loggable {}
