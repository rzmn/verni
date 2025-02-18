import AsyncExtensions
import Foundation
import Logging
import PersistentStorage
internal import SQLite

typealias Expression = SQLite.Expression
typealias Operation = PersistentStorage.Operation

@StorageActor class SQLiteUserStorage {
    struct InitialData {
        let refreshToken: String
        let operations: [Operation]
    }

    let logger: Logger
    private let connection: SqliteConnectionHolder

    private let hostId: HostId
    private let inMemoryCache: InMemoryCache

    init(
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void,
        hostId: HostId,
        initialData: InitialData?,
        logger: Logger
    ) async throws {
        self.connection = SqliteConnectionHolder(
            logger: logger,
            database: database,
            invalidator: invalidator
        )
        self.hostId = hostId
        self.logger = logger
        if let initialData {
            let deviceId = UUID().uuidString
            inMemoryCache = InMemoryCache(
                refreshToken: initialData.refreshToken,
                deviceId: deviceId,
                operations: initialData.operations
            )
            try updateStringForHost(value: deviceId, schema: .deviceId)
            try await update(operations: initialData.operations)
            try await update(refreshToken: initialData.refreshToken)
        } else {
            let operations: [Operation] = try database.getOperations()
            let token: String = try database.getValueForHost(
                host: hostId,
                schema: .refreshToken
            )
            let deviceId: String = try database.getValueForHost(
                host: hostId,
                schema: .deviceId
            )
            inMemoryCache = InMemoryCache(
                refreshToken: token,
                deviceId: deviceId,
                operations: operations
            )
        }
    }
}

extension SQLiteUserStorage: UserStorage {
    var refreshToken: String {
        get async {
            await inMemoryCache.refreshToken
        }
    }

    var operations: [Operation] {
        get async {
            await inMemoryCache.operations
        }
    }

    var userId: HostId {
        get async {
            hostId
        }
    }

    var deviceId: DeviceId {
        get async {
            await inMemoryCache.deviceId
        }
    }

    func update(operations: [Operation]) async throws {
        guard let database = connection.database else {
            return
        }
        try database.upsert(operations: operations)
        await inMemoryCache.update(
            operations: operations.merged(with: inMemoryCache.operations).all
        )
    }

    private func updateStringForHost(value: String, schema: Schema) throws {
        guard let database = connection.database else {
            return
        }
        try database.run(
            Table(schema.tableName)
                .insert(
                    or: .replace,
                    try [
                        Expression(schema.identifierKey) <- CodableBlob(value: hostId),
                        Expression(schema.valueKey) <- CodableBlob(value: value),
                    ]
                )
        )
    }

    func update(refreshToken: String) async throws {
        try updateStringForHost(value: refreshToken, schema: .refreshToken)
        await inMemoryCache.update(refreshToken: refreshToken)
    }

    func close() {
        connection.close()
    }

    func invalidate() {
        connection.invalidate()
    }
}

extension SQLiteUserStorage: Loggable {}
