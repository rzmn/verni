import Logging
import Foundation
import PersistentStorage
import Base
import DataTransferObjects
internal import SQLite

private struct FriendshipKindSet: OptionSet {
    static let friends = FriendshipKindSet(rawValue: 1 << FriendshipKindDto.friends.rawValue)
    static let subscription = FriendshipKindSet(rawValue: 1 << FriendshipKindDto.subscription.rawValue)
    static let subscriber = FriendshipKindSet(rawValue: 1 << FriendshipKindDto.subscriber.rawValue)

    var rawValue: Int64
    init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    init(set: Set<FriendshipKindDto>) {
        self = set.reduce(into: [], { set, item in
            set.insert(FriendshipKindSet(rawValue: 1 << item.rawValue))
        })
    }

    var setValue: Set<FriendshipKindDto> {
        FriendshipKindDto.allCases.reduce(into: Set()) { set, item in
            switch item {
            case
                    .friends where contains(.friends),
                    .subscription where contains(.subscription),
                    .subscriber where contains(.subscriber):
                set.insert(item)
            default:
                break
            }
        }
    }
}

@StorageActor class SQLitePersistency: Persistency {
    let logger: Logger

    private let db: Connection
    private let dbInvalidationHandler: () throws -> Void
    private let hostId: UserDto.ID
    private let queue = DispatchQueue(label: "\(SQLitePersistency.self)")
    private var refreshToken: String
    private var serialScheduler: AsyncSerialScheduler
    private var detachedTasks = [Task<Void, Never>]()

    init(
        db: Connection,
        dbInvalidationHandler: @escaping () throws -> Void,
        hostId: UserDto.ID,
        refreshToken: String,
        logger: Logger,
        storeInitialToken: Bool = false
    ) {
        self.db = db
        self.hostId = hostId
        self.refreshToken = refreshToken
        self.logger = logger
        self.dbInvalidationHandler = dbInvalidationHandler
        serialScheduler = AsyncSerialScheduler()
        guard storeInitialToken else {
            return
        }
        detachedTasks.append(
            Task.detached {
                await self.serialScheduler.run { @StorageActor in
                    do {
                        try self.db.run(Schema.Tokens.table.insert(
                            Schema.Tokens.Keys.id <- self.hostId,
                            Schema.Tokens.Keys.token <- refreshToken
                        ))
                    } catch {
                        self.logE { "failed to insert token error: \(error)" }
                    }
                }
            }
        )
    }

    func getRefreshToken() async -> String {
        refreshToken
    }

    func update(refreshToken: String) async {
        self.refreshToken = refreshToken
        detachedTasks.append(
            Task.detached { @StorageActor in
                await self.serialScheduler.run { @StorageActor in
                    do {
                        try self.db.run(
                            Schema.Tokens.table
                                .filter(Schema.Tokens.Keys.id == self.hostId)
                                .update(Schema.Tokens.Keys.token <- refreshToken)
                        )
                    } catch {
                        self.logE { "failed to update token error: \(error)" }
                    }
                }
            }
        )
    }

    public func getHostInfo() async -> UserDto? {
        await user(id: hostId)
    }

    public func user(id: UserDto.ID) async -> UserDto? {
        do {
            guard let row = try db.prepare(Schema.Users.table).first(where: { row in
                guard try row.get(Schema.Users.Keys.id) == id else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Users.Keys.payload).value
        } catch {
            self.logE { "fetch user failed error: \(error)" }
            return nil
        }
    }

    public func update(users: [UserDto]) async {
        do {
            try users.forEach {
                try db.run(Schema.Users.table.upsert(
                    Schema.Users.Keys.id <- $0.login,
                    Schema.Users.Keys.payload <- CodableBlob(value: $0),
                    onConflictOf: Schema.Users.Keys.id
                ))
            }
        } catch {
            self.logE { "failed to update users error: \(error)" }
        }
    }

    func getSpendingCounterparties() async -> [SpendingsPreviewDto]? {
        do {
            guard let row = try db.prepare(Schema.SpendingCounterparties.table).first(where: { row in
                guard try row.get(Schema.SpendingCounterparties.Keys.id) == hostId else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingCounterparties.Keys.payload).value
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreviewDto]) async {
        do {
            try self.db.run(Schema.SpendingCounterparties.table.upsert(
                Schema.SpendingCounterparties.Keys.id <- hostId,
                Schema.SpendingCounterparties.Keys.payload <- CodableBlob(value: counterparties),
                onConflictOf: Schema.SpendingCounterparties.Keys.id
            ))
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    func getSpendingsHistory(counterparty: UserDto.ID) async -> [IdentifiableDealDto]? {
        do {
            guard let row = try db.prepare(Schema.SpendingsHistory.table).first(where: { row in
                guard try row.get(Schema.SpendingsHistory.Keys.id) == counterparty else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingsHistory.Keys.payload).value
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingsHistory(counterparty: UserDto.ID, history: [IdentifiableDealDto]) async {
        do {
            try self.db.run(Schema.SpendingsHistory.table.upsert(
                Schema.SpendingsHistory.Keys.id <- counterparty,
                Schema.SpendingsHistory.Keys.payload <- CodableBlob(value: history),
                onConflictOf: Schema.SpendingsHistory.Keys.id
            ))
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    func getFriends(set: Set<FriendshipKindDto>) async -> [FriendshipKindDto: [UserDto]]? {
        do {
            guard let row = try db.prepare(Schema.Friends.table).first(where: { row in
                guard try row.get(Schema.Friends.Keys.id) == FriendshipKindSet(set: set).rawValue else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Friends.Keys.payload).value
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func storeFriends(_ friends: [FriendshipKindDto: [UserDto]]) async {
        do {
            try self.db.run(Schema.Friends.table.upsert(
                Schema.Friends.Keys.id <- FriendshipKindSet(set: Set(friends.keys)).rawValue,
                Schema.Friends.Keys.payload <- CodableBlob(value: friends),
                onConflictOf: Schema.Friends.Keys.id
            ))
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    func close() async {
        for task in detachedTasks {
            await task.value
        }
        detachedTasks.removeAll()
    }

    func invalidate() async {
        await close()
        let handler = dbInvalidationHandler
        Task.detached { @StorageActor in
            do {
                try handler()
            } catch {
                self.logE { "failed to invalidate db: \(error)" }
            }
        }
    }
}

extension SQLitePersistency: Loggable {}
