import AsyncExtensions
internal import Base
import Filesystem
import Foundation
import Logging
import PersistentStorage
internal import SQLite

public actor SQLitePersistencyFactory {
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

extension SQLitePersistencyFactory: PersistencyFactory {
    public func awake(host: HostId) async -> Persistency? {
        await doAwake(host: host)
    }

    @StorageActor private func doAwake(host: HostId) async -> Persistency? {
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
                invalidator: invalidator(
                    for: host,
                    pathManager: pathManager
                ),
                hostId: host,
                refreshToken: nil,
                logger: logger
            )
        } catch {
            logE { "failed to create persistency from url due error: \(error)" }
            return nil
        }
    }

    public func create<each D: Descriptor>(
        host: HostId,
        descriptors: DescriptorTuple<repeat each D>,
        refreshToken: String
    ) async throws -> Persistency {
        try await doCreate(host: host, descriptors: descriptors, refreshToken: refreshToken)
    }

    @StorageActor private func doCreate<each D: Descriptor>(
        host: HostId,
        descriptors: DescriptorTuple<repeat each D>,
        refreshToken: String
    ) async throws -> Persistency {
        logI { "creating persistence..." }
        let pathManager = try createDatabasePathManager()
        let database = try pathManager.create(id: host).connection()
        do {
            try createTables(for: database, descriptors: descriptors)
        } catch {
            pathManager.invalidate(id: host)
            throw error
        }
        return try await SQLitePersistency(
            database: database,
            invalidator: invalidator(
                for: host,
                pathManager: pathManager
            ),
            hostId: host,
            refreshToken: refreshToken,
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

    @StorageActor private func createTables<each D: Descriptor>(
        for database: Connection,
        descriptors: DescriptorTuple<repeat each D>
    ) throws {
        repeat try createTable(descriptor: each descriptors.content, database: database)
    }

    @StorageActor private func createTable<D: Descriptor>(
        descriptor: D, database: Connection
    ) throws {
        try database.run(
            Table(descriptor.id).create { table in
                table.column(
                    Expression<CodableBlob<D.Key>>(Schema.identifierKey), primaryKey: true)
                table.column(Expression<CodableBlob<D.Value>>(Schema.valueKey))
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

extension SQLitePersistencyFactory: Loggable {}
