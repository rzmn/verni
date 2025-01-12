import AsyncExtensions
import Filesystem
import Foundation
import Logging
import PersistentStorage
import Api
internal import SQLite

public actor SQLiteStorageFactory {
    public let logger: Logger
    let dbDirectory: URL
    private let taskFactory: TaskFactory
    private let fileManager: Filesystem.FileManager

    public init(
        logger: Logger,
        dbDirectory: URL,
        taskFactory: TaskFactory,
        fileManager: Filesystem.FileManager
    ) throws {
        self.dbDirectory = dbDirectory
        self.logger = logger
        self.taskFactory = taskFactory
        self.fileManager = fileManager
    }
}

extension SQLiteStorageFactory: StorageFactory {
    nonisolated public func sandbox() throws -> SandboxStorage {
        MustInitSandboxStorage { [unowned self] in
            try await doProvideSandbox()
        }
    }
    
    @StorageActor private func doProvideSandbox() async throws -> SandboxStorage {
        logI { "providing sandbox storage..." }
        let pathManager = try createDatabasePathManager()
        logI { "looking for existed storage" }
        let item: SqliteDbPathManager.Item
        let connection: Connection
        if let existed = try pathManager.items.first(where: { $0.id == .sandbox }) {
            logI { "found storage" }
            item = existed
            connection = try item.connection()
            logI { "created connection" }
        } else {
            item = try pathManager.create(id: .sandbox)
            logI { "created storage" }
            do {
                connection = try item.connection()
                try createTablesForSandbox(database: connection)
                logI { "storage successfully prepared" }
            } catch {
                logI { "failed to prepage storage, invalidating, error: \(error)" }
                pathManager.invalidate(id: .sandbox)
                throw error
            }
        }
        return try SQLiteSandboxStorage(
            logger: logger,
            database: try item.connection(),
            invalidator: invalidator(
                for: .sandbox,
                pathManager: pathManager
            )
        )
    }
    
    public func awake(host: HostId) async -> UserStorage? {
        await doAwake(host: host)
    }

    @StorageActor private func doAwake(host: HostId) async -> UserStorage? {
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
            return try await SQLiteUserStorage(
                database: try item.connection(),
                invalidator: invalidator(
                    for: host,
                    pathManager: pathManager
                ),
                hostId: host,
                initialData: nil,
                logger: logger
            )
        } catch {
            logE { "failed to create persistency from url due error: \(error)" }
            return nil
        }
    }

    public func create(
        host: HostId,
        refreshToken: String,
        operations: [PersistentStorage.Operation]
    ) async throws -> UserStorage {
        try await doCreate(host: host, refreshToken: refreshToken, operations: operations)
    }

    @StorageActor private func doCreate(
        host: HostId,
        refreshToken: String,
        operations: [Operation]
    ) async throws -> UserStorage {
        logI { "creating persistence..." }
        let pathManager = try createDatabasePathManager()
        let database = try pathManager.create(id: host).connection()
        do {
            try createTablesForUser(database: database)
        } catch {
            pathManager.invalidate(id: host)
            throw error
        }
        return try await SQLiteUserStorage(
            database: database,
            invalidator: invalidator(
                for: host,
                pathManager: pathManager
            ),
            hostId: host,
            initialData: SQLiteUserStorage.InitialData(
                refreshToken: refreshToken,
                operations: operations
            ),
            logger: logger
        )
    }

    @StorageActor private func createDatabasePathManager() throws -> any DbPathManager<
        SqliteDbPathManager.Item
    > {
        try SqliteDbPathManager(
            logger: logger.with(prefix: "📁"),
            containerDirectory: dbDirectory,
            versionLabel: "v1",
            pathManager: fileManager
        )
    }
    
    @StorageActor private func createTablesForSandbox(
        database: Connection
    ) throws {
        let operations = Schema.operations
        try database.run(
            Table(operations.tableName).create { table in
                table.column(
                    Expression<CodableBlob<String>>(operations.identifierKey),
                    primaryKey: true
                )
                table.column(
                    Expression<CodableBlob<Components.Schemas.Operation>>(operations.valueKey)
                )
            }
        )
    }

    @StorageActor private func createTablesForUser(
        database: Connection
    ) throws {
        let operations = Schema.operations
        try database.run(
            Table(operations.tableName).create { table in
                table.column(
                    Expression<CodableBlob<String>>(operations.identifierKey),
                    primaryKey: true
                )
                table.column(
                    Expression<CodableBlob<PersistentStorage.Operation>>(operations.valueKey)
                )
            }
        )
        let refreshToken = Schema.refreshToken
        try database.run(
            Table(refreshToken.tableName).create { table in
                table.column(
                    Expression<CodableBlob<String>>(refreshToken.identifierKey),
                    primaryKey: true
                )
                table.column(
                    Expression<CodableBlob<String>>(refreshToken.valueKey)
                )
            }
        )
        let deviceId = Schema.deviceId
        try database.run(
            Table(deviceId.tableName).create { table in
                table.column(
                    Expression<CodableBlob<String>>(deviceId.identifierKey),
                    primaryKey: true
                )
                table.column(
                    Expression<CodableBlob<String>>(deviceId.valueKey)
                )
            }
        )
    }

    @StorageActor private func invalidator(
        for host: HostId,
        pathManager: any DbPathManager<SqliteDbPathManager.Item>
    ) -> @StorageActor @Sendable () -> Void {
        return {
            pathManager.invalidate(id: host)
        }
    }
}

extension SQLiteStorageFactory: Loggable {}
