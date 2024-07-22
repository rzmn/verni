import Domain
import Logging
import Foundation
import PersistentStorage
import Base
internal import ApiDomainConvenience
internal import DataTransferObjects
internal import SQLite

@StorageActor class DefaultPersistency: Persistency {
    let logger: Logger

    private let db: Connection
    private let dbInvalidationHandler: () throws -> Void
    private let hostId: User.ID
    private let queue = DispatchQueue(label: "\(DefaultPersistency.self)")
    private var refreshToken: String
    private var serialScheduler: AsyncSerialScheduler

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
    }

    func getRefreshToken() async -> String {
        refreshToken
    }

    func update(refreshToken: String) async {
        self.refreshToken = refreshToken
        Task.detached { @StorageActor in
            await self.serialScheduler.run { @StorageActor in
                do {
                    try self.db.run(Schema.Tokens.table.update(
                        Schema.Tokens.Keys.id <- self.hostId,
                        Schema.Tokens.Keys.token <- refreshToken
                    ))
                } catch {
                    self.logE { "failed to update token error: \(error)" }
                }
            }
        }
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
            return User(
                id: id,
                status: User.FriendStatus(
                    dto: UserDto.FriendStatus(
                        rawValue: Int(try row.get(Schema.Users.Keys.friendStatus))
                    ) ?? .no
                )
            )
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
                    Schema.Users.Keys.friendStatus <- Int64(UserDto.FriendStatus(domain: $0.status).rawValue),
                    onConflictOf: Schema.Users.Keys.id
                ))
            }
        } catch {
            self.logE { "failed to update users error: \(error)" }
        }
    }

    func invalidate() async {
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
