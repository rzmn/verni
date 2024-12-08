import Logging
import Foundation
import PersistentStorage
import Base
import DataTransferObjects
import AsyncExtensions
internal import SQLite

typealias Expression = SQLite.Expression

@StorageActor class SQLitePersistency: Persistency {
    let logger: Logger
    
    var refreshToken: String {
        get async {
            (inMemoryCache[Schemas.refreshToken.unkeyedIndex] as? String) ?? initialRefreshToken
        }
    }
    
    var userId: UserDto.Identifier {
        get async {
            hostId
        }
    }

    private let encoder = JSONEncoder()
    private let taskFactory: TaskFactory
    private let database: Connection
    private let hostId: UserDto.Identifier
    private var initialRefreshToken: String!
    private var inMemoryCache = [AnyHashable: Any]()
    private var onDeinit: (_ shouldInvalidate: Bool) -> Void
    private(set) var shouldInvalidate = false

    init(
        database: Connection,
        onDeinit: @escaping (_ shouldInvalidate: Bool) -> Void,
        hostId: UserDto.Identifier,
        refreshToken: String?,
        logger: Logger,
        taskFactory: TaskFactory
    ) throws {
        self.database = database
        self.hostId = hostId
        self.logger = logger
        self.onDeinit = onDeinit
        self.taskFactory = taskFactory
        if let refreshToken {
            self.initialRefreshToken = refreshToken
            do {
                try doUpdate(value: refreshToken, for: Schemas.refreshToken.unkeyedIndex)
            } catch {
                logE { "failed to insert token error: \(error)" }
            }
        } else {
            guard let refreshToken = try doGet(descriptor: Schemas.refreshToken.unkeyedIndex) else {
                throw SQLite.QueryError.unexpectedNullValue(name: "\(Schemas.refreshToken.id)")
            }
            self.initialRefreshToken = refreshToken
        }
    }

    private static var identifierKey: String {
        "id"
    }
    
    private static var valueKey: String {
        "value"
    }
    
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        descriptor: Schema<Key, Value>.Index
    ) -> Value? {
        get {
            do {
                return try doGet(descriptor: descriptor)
            } catch {
                logE { "failed to perform get for \(descriptor)" }
                return nil
            }
        }
    }
    
    private func doGet<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        descriptor: Schema<Key, Value>.Index
    ) throws -> Value? {
        let row = try database.prepare(Table(descriptor.schema.id))
            .first { row in
                let blob = try row.get(
                    Expression<CodableBlob<Key>>(Self.identifierKey)
                )
                return blob.value == descriptor.key
            }
        let value = try row?.get(Expression<CodableBlob<Value>>(Self.valueKey)).value
        inMemoryCache[descriptor] = value
        return value
    }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for descriptor: Schema<Key, Value>.Index
    ) {
        do {
            try doUpdate(value: value, for: descriptor)
        } catch {
            return logE { "failed to perform upsert \(value) query for \(descriptor)" }
        }
    }
    
    private func doUpdate<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for descriptor: Schema<Key, Value>.Index
    ) throws {
        try database.run(
            Table(descriptor.schema.id)
                .upsert(
                    Expression(Self.identifierKey) <- CodableBlob(value: descriptor.key),
                    Expression(Self.valueKey) <- CodableBlob(value: value),
                    onConflictOf: Expression<CodableBlob<Key>>(Self.identifierKey)
                )
        )
        inMemoryCache[descriptor] = value
    }
    
    static func createTable<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        for schema: Schema<Key, Value>,
        database: Connection
    ) throws {
        try database.run(Table(schema.id).create { table in
            table.column(Expression<CodableBlob<Key>>(identifierKey), primaryKey: true)
            table.column(Expression<CodableBlob<Value>>(valueKey))
        })
    }

    func close() {
        // empty
    }

    func invalidate() {
        logI { "invalidating db..." }
        close()
        shouldInvalidate = true
    }
}

extension SQLitePersistency: Loggable {}
