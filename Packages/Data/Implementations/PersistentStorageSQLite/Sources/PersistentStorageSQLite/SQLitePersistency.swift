import AsyncExtensions
internal import Base
import Foundation
import Infrastructure
import Logging
import PersistentStorage
internal import SQLite

typealias Expression = SQLite.Expression

@StorageActor class SQLitePersistency {
    let logger: Logger
    private(set) var database: Connection?

    private let encoder = JSONEncoder()
    private let hostId: HostId
    private var currentRefreshToken: String!
    private let inMemoryCache = InMemoryCache()
    private let invalidator: @StorageActor @Sendable () -> Void

    init(
        database: Connection,
        invalidator: @escaping @StorageActor @Sendable () -> Void,
        hostId: HostId,
        refreshToken: String?,
        logger: Logger
    ) async throws {
        self.database = database
        self.hostId = hostId
        self.logger = logger
        self.invalidator = invalidator
        if let refreshToken {
            self.currentRefreshToken = refreshToken
            try await doUpdate(value: refreshToken, for: Schema.refreshToken.unkeyed)
        } else {
            guard let refreshToken = try await doGet(index: Schema.refreshToken.unkeyed) else {
                throw SQLite.QueryError.unexpectedNullValue(name: "\(Schema.refreshToken.id)")
            }
            self.currentRefreshToken = refreshToken
        }
    }
}

extension SQLitePersistency: Persistency {
    var refreshToken: String {
        get async {
            currentRefreshToken
        }
    }

    var userId: HostId {
        get async {
            hostId
        }
    }

    subscript<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        index: Index<D>
    ) -> Value? where D.Key == Key, D.Value == Value {
        get async {
            do {
                return try await doGet(index: index)
            } catch {
                logE { "failed to perform get for \(index)" }
                return nil
            }
        }
    }

    private func doGet<
        Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor
    >(
        index: Index<D>
    ) async throws -> Value? where D.Key == Key, D.Value == Value {
        if let value = await inMemoryCache[index] {
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

    func update<Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor>(
        value: Value,
        for index: Index<D>
    ) async where D.Key == Key, D.Value == Value {
        do {
            try await doUpdate(value: value, for: index)
        } catch {
            return logE { "failed to perform upsert \(value) query for \(index)" }
        }
    }

    private func doUpdate<
        Key: Sendable & Codable & Equatable, Value: Sendable & Codable, D: Descriptor
    >(
        value: Value,
        for index: Index<D>
    ) async throws where D.Key == Key, D.Value == Value {
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
        if index.descriptor.id == Schema.refreshToken.id, let token = value as? String {
            currentRefreshToken = token
        }
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
