import Logging
import Foundation
import PersistentStorage
import DataTransferObjects
import AsyncExtensions
internal import Base
internal import SQLite

typealias Expression = SQLite.Expression

@StorageActor class SQLitePersistency {
    let logger: Logger
    
    private let encoder = JSONEncoder()
    private let taskFactory: TaskFactory
    private var database: Connection?
    private let hostId: UserDto.Identifier
    private var initialRefreshToken: String!
    private let inMemoryCache = InMemoryCache()
    private let invalidator: @StorageActor @Sendable () -> Void

    init(
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void,
        hostId: UserDto.Identifier,
        refreshToken: String?,
        logger: Logger,
        taskFactory: TaskFactory
    ) async throws {
        self.database = database
        self.hostId = hostId
        self.logger = logger
        self.invalidator = invalidator
        self.taskFactory = taskFactory
        if let refreshToken {
            self.initialRefreshToken = refreshToken
            do {
                try await doUpdate(value: refreshToken, for: Schema.refreshToken.unkeyed)
            } catch {
                logE { "failed to insert token error: \(error)" }
            }
        } else {
            guard let refreshToken = try await doGet(index: Schema.refreshToken.unkeyed) else {
                throw SQLite.QueryError.unexpectedNullValue(name: "\(Schema.refreshToken.id)")
            }
            self.initialRefreshToken = refreshToken
        }
    }
}

extension SQLitePersistency: Persistency {
    var refreshToken: String {
        get async {
            await inMemoryCache
                .get(index: Schema.refreshToken.unkeyed)
            ?? initialRefreshToken
        }
    }
    
    var userId: UserDto.Identifier {
        get async {
            hostId
        }
    }
    
    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        index: Descriptor<Key, Value>.Index
    ) -> Value? {
        get async {
            do {
                return try await doGet(index: index)
            } catch {
                logE { "failed to perform get for \(index)" }
                return nil
            }
        }
    }
    
    private func doGet<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        index: Descriptor<Key, Value>.Index
    ) async throws -> Value? {
        if let value = await inMemoryCache.get(index: index) {
            return value
        }
        guard let database else {
            return nil
        }
        let row = try database.prepare(Table(index.descriptor.id))
            .first { row in
                let blob = try row.get(
                    Expression<CodableBlob<Key>>(Schema.identifierKey)
                )
                return blob.value == index.key
            }
        let value = try row?.get(Expression<CodableBlob<Value>>(Schema.valueKey)).value
        if let value {
            await inMemoryCache.update(value: value, for: index)
        }
        return value
    }
    
    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for descriptor: Descriptor<Key, Value>.Index
    ) async {
        do {
            try await doUpdate(value: value, for: descriptor)
        } catch {
            return logE { "failed to perform upsert \(value) query for \(descriptor)" }
        }
    }
    
    private func doUpdate<Key: Sendable & Codable & Equatable, Value: Sendable & Codable>(
        value: Value,
        for index: Descriptor<Key, Value>.Index
    ) async throws {
        guard let database else {
            return
        }
        try database.run(
            Table(index.descriptor.id)
                .upsert(
                    Expression(Schema.identifierKey) <- CodableBlob(value: index.key),
                    Expression(Schema.valueKey) <- CodableBlob(value: value),
                    onConflictOf: Expression<CodableBlob<Key>>(Schema.identifierKey)
                )
        )
        await inMemoryCache.update(value: value, for: index)
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
