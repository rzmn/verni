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
            return try await SQLitePersistency(
                database: database,
                onDeinit: { [pathManager] shouldInvalidate in
                    guard shouldInvalidate else {
                        return
                    }
                    do {
                        try pathManager.invalidate(owner: host)
                    } catch {
                        self.logE { "failed to invalidate db: \(error)" }
                    }
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
        let dbUrl = try pathManager.create(owner: host).dbUrl
        let database = try Connection(dbUrl.path)
        do {
            try createTables(for: database)
        } catch {
            try FileManager.default.removeItem(at: dbUrl)
            throw error
        }
        return try await SQLitePersistency(
            database: database,
            onDeinit: { [pathManager] shouldInvalidate in
                guard shouldInvalidate else {
                    return
                }
                do {
                    try pathManager.invalidate(owner: host)
                } catch {
                    self.logE { "failed to invalidate db: \(error)" }
                }
            },
            hostId: host,
            refreshToken: refreshToken,
            logger: logger,
            taskFactory: taskFactory
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
