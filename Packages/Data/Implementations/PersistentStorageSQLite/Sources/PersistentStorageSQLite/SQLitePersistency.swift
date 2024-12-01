import Logging
import Foundation
import PersistentStorage
import Base
import DataTransferObjects
import AsyncExtensions
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

    private let taskFactory: TaskFactory
    private let database: Connection
    private let hostId: UserDto.Identifier
    private var refreshToken: String
    private var onDeinit: (_ shouldInvalidate: Bool) -> Void
    private(set) var shouldInvalidate = false

    init(
        database: Connection,
        onDeinit: @escaping (_ shouldInvalidate: Bool) -> Void,
        hostId: UserDto.Identifier,
        refreshToken: String,
        logger: Logger,
        taskFactory: TaskFactory,
        storeInitialToken: Bool = false
    ) {
        self.database = database
        self.hostId = hostId
        self.refreshToken = refreshToken
        self.logger = logger
        self.onDeinit = onDeinit
        self.taskFactory = taskFactory
        if storeInitialToken {
            do {
                try database.run(Schema.Tokens.table.insert(
                    Schema.Tokens.Keys.id <- self.hostId,
                    Schema.Tokens.Keys.token <- refreshToken
                ))
            } catch {
                logE { "failed to insert token error: \(error)" }
            }
        }
    }

    func userId() -> UserDto.Identifier {
        hostId
    }

    func getRefreshToken() -> String {
        refreshToken
    }

    func update(refreshToken: String) {
        self.refreshToken = refreshToken
        do {
            try database.run(
                Schema.Tokens.table
                    .filter(Schema.Tokens.Keys.id == self.hostId)
                    .update(Schema.Tokens.Keys.token <- refreshToken)
            )
        } catch {
            logE { "failed to update token error: \(error)" }
        }
    }

    public func getProfile() -> ProfileDto? {
        do {
            guard let row = try database.prepare(Schema.Profile.table).first(where: { row in
                guard try row.get(Schema.Profile.Keys.id) == hostId else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Profile.Keys.payload).value
        } catch {
            logE { "fetch profile failed error: \(error)" }
            return nil
        }
    }

    func update(profile: ProfileDto) {
        assert(profile.user.id == hostId)
        do {
            try database.run(Schema.Profile.table.upsert(
                Schema.Profile.Keys.id <- profile.user.id,
                Schema.Profile.Keys.payload <- CodableBlob(value: profile),
                onConflictOf: Schema.Profile.Keys.id
            ))
        } catch {
            logE { "failed to update profile error: \(error)" }
        }
    }

    public func user(id: UserDto.Identifier) -> UserDto? {
        do {
            guard let row = try database.prepare(Schema.Users.table).first(where: { row in
                guard try row.get(Schema.Users.Keys.id) == id else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Users.Keys.payload).value
        } catch {
            logE { "fetch user failed error: \(error)" }
            return nil
        }
    }

    public func update(users: [UserDto]) {
        do {
            try users.forEach {
                try database.run(Schema.Users.table.upsert(
                    Schema.Users.Keys.id <- $0.id,
                    Schema.Users.Keys.payload <- CodableBlob(value: $0),
                    onConflictOf: Schema.Users.Keys.id
                ))
            }
        } catch {
            logE { "failed to update users error: \(error)" }
        }
    }

    func getSpendingCounterparties() -> [BalanceDto]? {
        do {
            guard let row = try database.prepare(Schema.SpendingCounterparties.table).first(where: { row in
                guard try row.get(Schema.SpendingCounterparties.Keys.id) == hostId else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingCounterparties.Keys.payload).value
        } catch {
            logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingCounterparties(_ counterparties: [BalanceDto]) {
        do {
            try database.run(Schema.SpendingCounterparties.table.upsert(
                Schema.SpendingCounterparties.Keys.id <- hostId,
                Schema.SpendingCounterparties.Keys.payload <- CodableBlob(value: counterparties),
                onConflictOf: Schema.SpendingCounterparties.Keys.id
            ))
        } catch {
            logE { "failed to update spending counterparties: \(error)" }
        }
    }

    func getSpendingsHistory(counterparty: UserDto.Identifier) -> [IdentifiableExpenseDto]? {
        do {
            guard let row = try database.prepare(Schema.SpendingsHistory.table).first(where: { row in
                guard try row.get(Schema.SpendingsHistory.Keys.id) == counterparty else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.SpendingsHistory.Keys.payload).value
        } catch {
            logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func updateSpendingsHistory(counterparty: UserDto.Identifier, history: [IdentifiableExpenseDto]) {
        do {
            try database.run(Schema.SpendingsHistory.table.upsert(
                Schema.SpendingsHistory.Keys.id <- counterparty,
                Schema.SpendingsHistory.Keys.payload <- CodableBlob(value: history),
                onConflictOf: Schema.SpendingsHistory.Keys.id
            ))
        } catch {
            logE { "failed to update spending history: \(error)" }
        }
    }

    func getFriends(set: Set<FriendshipKindDto>) -> [FriendshipKindDto: [UserDto]]? {
        do {
            guard let row = try database.prepare(Schema.Friends.table).first(where: { row in
                guard try row.get(Schema.Friends.Keys.id) == FriendshipKindSet(set: set).rawValue else {
                    return false
                }
                return true
            }) else {
                return nil
            }
            return try row.get(Schema.Friends.Keys.payload).value
        } catch {
            logE { "fetch spending counterparties failed error: \(error)" }
            return nil
        }
    }

    func update(friends: [FriendshipKindDto: [UserDto]], for set: Set<FriendshipKindDto>) {
        do {
            try database.run(Schema.Friends.table.upsert(
                Schema.Friends.Keys.id <- FriendshipKindSet(set: set).rawValue,
                Schema.Friends.Keys.payload <- CodableBlob(value: friends),
                onConflictOf: Schema.Friends.Keys.id
            ))
        } catch {
            logE { "failed to update friends: \(error)" }
        }
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
