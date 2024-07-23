import Domain
import Logging
import Foundation
import PersistentStorage
import Base
internal import ApiDomainConvenience
internal import DataTransferObjects
internal import SQLite

private struct FriendshipKindSet: OptionSet {
    static let friends = FriendshipKindSet(rawValue: 1 << FriendshipKind.friends.rawValue)
    static let incoming = FriendshipKindSet(rawValue: 1 << FriendshipKind.incoming.rawValue)
    static let pending = FriendshipKindSet(rawValue: 1 << FriendshipKind.pending.rawValue)

    var rawValue: Int64
    init(rawValue: Int64) {
        self.rawValue = rawValue
    }

    init(set: Set<FriendshipKind>) {
        self = set.reduce(into: [], { set, item in
            set.insert(FriendshipKindSet(rawValue: 1 << item.rawValue))
        })
    }

    var setValue: Set<FriendshipKind> {
        FriendshipKind.allCases.reduce(into: Set()) { set, item in
            switch item {
            case .friends where contains(.friends), .incoming where contains(.incoming), .pending where contains(.pending):
                set.insert(item)
            default:
                break
            }
        }
    }
}

@StorageActor class DefaultPersistency: Persistency {
    let logger: Logger

    private let db: Connection
    private let dbInvalidationHandler: () throws -> Void
    private let hostId: User.ID
    private let queue = DispatchQueue(label: "\(DefaultPersistency.self)")
    private var refreshToken: String
    private var serialScheduler: AsyncSerialScheduler
    private var detachedTasks = [Task<Void, Never>]()

    init(
        db: Connection,
        dbInvalidationHandler: @escaping () throws -> Void,
        hostId: User.ID,
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

    public func getHostInfo() async -> User? {
        await user(id: hostId)
    }

    public func user(id: User.ID) async -> User? {
        do {
            guard let row = try db.prepare(Schema.Users.table).first(where: { row in
                guard try row.get(Schema.Users.Keys.id) == id else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return User(dto: try row.get(Schema.Users.Keys.payload).value)
        } catch {
            self.logE { "fetch user failed error: \(error)" }
            return nil
        }
    }

    public func update(users: [User]) async {
        do {
            try users.forEach {
                try db.run(Schema.Users.table.upsert(
                    Schema.Users.Keys.id <- $0.id,
                    Schema.Users.Keys.payload <- CodableBlob(value: UserDto(domain: $0)),
                    onConflictOf: Schema.Users.Keys.id
                ))
            }
        } catch {
            self.logE { "failed to update users error: \(error)" }
        }
    }

    func getSpendingCounterparties() async -> [SpendingsPreview]? {
        do {
            guard let row = try db.prepare(Schema.SpendingCounterparties.table).first(where: { row in
                guard try row.get(Schema.SpendingCounterparties.Keys.id) == hostId else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingCounterparties.Keys.payload).value.map(SpendingsPreview.init)
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        do {
            try self.db.run(Schema.SpendingCounterparties.table.upsert(
                Schema.SpendingCounterparties.Keys.id <- hostId,
                Schema.SpendingCounterparties.Keys.payload <- CodableBlob(value: counterparties.map(SpendingsPreviewDto.init)),
                onConflictOf: Schema.SpendingCounterparties.Keys.id
            ))
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    func getSpendingsHistory(counterparty: User.ID) async -> [IdentifiableSpending]? {
        do {
            guard let row = try db.prepare(Schema.SpendingsHistory.table).first(where: { row in
                guard try row.get(Schema.SpendingsHistory.Keys.id) == counterparty else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingsHistory.Keys.payload).value.map(IdentifiableSpending.init)
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async {
        do {
            try self.db.run(Schema.SpendingsHistory.table.upsert(
                Schema.SpendingsHistory.Keys.id <- counterparty,
                Schema.SpendingsHistory.Keys.payload <- CodableBlob(value: history.map(IdentifiableDealDto.init)),
                onConflictOf: Schema.SpendingsHistory.Keys.id
            ))
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    func getFriends(set: Set<FriendshipKind>) async -> [FriendshipKind: [User]]? {
        do {
            guard let row = try db.prepare(Schema.Friends.table).first(where: { row in
                guard try row.get(Schema.Friends.Keys.id) == FriendshipKindSet(set: set).rawValue else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Friends.Keys.payload).value.reduce(into: [:]) { dict, item in
                dict[FriendshipKind(dto: item.key)]  = item.value.map(User.init)
            }
        } catch {
            self.logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func storeFriends(_ friends: [FriendshipKind: [User]]) async {
        do {
            try self.db.run(Schema.Friends.table.upsert(
                Schema.Friends.Keys.id <- FriendshipKindSet(set: Set(friends.keys)).rawValue,
                Schema.Friends.Keys.payload <- CodableBlob(
                    value: friends.reduce(into: [:], { dict, item in
                        dict[FriendshipKindDto(domain: item.key)] = item.value.map(UserDto.init)
                    })
                ),
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

extension DefaultPersistency: Loggable {}
