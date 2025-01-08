import AsyncExtensions
internal import Base
import Foundation
import Infrastructure
import Logging
import PersistentStorage
internal import SQLite

typealias Expression = SQLite.Expression
typealias Operation = PersistentStorage.Operation

extension Sequence where Element == Operation {
    func sorted() -> [Self.Element] {
        sorted { lhs, rhs in
            guard lhs.timestamp != rhs.timestamp else {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }
}

@StorageActor class SQLitePersistency {
    struct InitialData {
        let refreshToken: String
        let operations: [Operation]
    }

    let logger: Logger
    private(set) var database: Connection?

    private let hostId: HostId
    private let inMemoryCache: InMemoryCache
    private let invalidator: @StorageActor @Sendable () -> Void

    init(
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void,
        hostId: HostId,
        initialData: InitialData?,
        logger: Logger
    ) async throws {
        self.database = database
        self.hostId = hostId
        self.logger = logger
        self.invalidator = invalidator
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
            let operations = try await Self.getOperations(
                database: database,
                cache: nil
            )
            let token = try await Self.getRefreshToken(
                host: hostId,
                database: database,
                cache: nil
            )
            let deviceId = try await Self.getDeviceId(
                host: hostId,
                database: database,
                cache: nil
            )
            inMemoryCache = InMemoryCache(
                refreshToken: token,
                deviceId: deviceId,
                operations: operations
            )
        }
    }
}

extension SQLitePersistency: Persistency {
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

    private static func getOperations(database: Connection, cache: InMemoryCache?) async throws -> [Operation] {
        if let value = await cache?.operations {
            return value
        }
        let operations = try database.prepare(Table(Schema.operations.tableName))
            .map { row in
                try row.get(Expression<CodableBlob<Operation>>(Schema.operations.valueKey)).value
            }
            .sorted()
        await cache?.update(operations: operations)
        return operations
    }

    func update(operations: [Operation]) async throws {
        guard let database else {
            return
        }
        try database.run(
            Table(Schema.operations.tableName)
                .insertMany(
                    or: .replace,
                    operations.map { operation in
                        try [
                            Expression(Schema.operations.identifierKey) <- CodableBlob(value: operation.id),
                            Expression(Schema.operations.valueKey) <- CodableBlob(value: operation),
                        ]
                    }
                )
        )
        await inMemoryCache.update(operations: operations)
    }

    private static func getRefreshToken(
        host: HostId,
        database: Connection,
        cache: InMemoryCache?
    ) async throws -> String {
        let token = try await getStringForHost(
            host: host,
            schema: .refreshToken,
            database: database,
            cache: cache
        )
        await cache?.update(refreshToken: token)
        return token
    }

    private static func getDeviceId(
        host: HostId,
        database: Connection,
        cache: InMemoryCache?
    ) async throws -> String {
        let id = try await getStringForHost(
            host: host,
            schema: .deviceId,
            database: database,
            cache: cache
        )
        return id
    }

    private static func getStringForHost(
        host: HostId,
        schema: Schema,
        database: Connection,
        cache: InMemoryCache?
    ) async throws -> String {
        if let value = await cache?.refreshToken {
            return value
        }
        let value = try database.prepare(Table(schema.tableName))
            .first { row in
                let id = try row.get(
                    Expression<CodableBlob<String>>(schema.identifierKey)
                ).value
                return id == host
            }?
            .get(Expression<CodableBlob<String>>(schema.valueKey)).value
        guard let value else {
            throw SQLite.QueryError.unexpectedNullValue(name: "\(schema.tableName)")
        }
        return value
    }

    private func updateStringForHost(value: String, schema: Schema) throws {
        guard let database else {
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
        database = nil
    }

    func invalidate() {
        logI { "invalidating db..." }
        close()
        invalidator()
    }
}

extension SQLitePersistency: Loggable {}
