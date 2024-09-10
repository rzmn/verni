import Domain
import Api
import Logging
import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultUsersRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let offline: UsersOfflineMutableRepository
    private let taskFactory: TaskFactory

    public init(
        api: ApiProtocol,
        logger: Logger,
        offline: UsersOfflineMutableRepository,
        taskFactory: TaskFactory
    ) {
        self.api = api
        self.logger = logger
        self.offline = offline
        self.taskFactory = taskFactory
    }
}

extension DefaultUsersRepository: UsersRepository {
    public func getUsers(ids: [User.ID]) async throws(GeneralError) -> [User] {
        logI { "getUsers [\(ids.count) ids]" }
        if ids.isEmpty {
            logI { "get users query is empty, returning immediatly" }
            return []
        }
        let users: [User]
        do {
            users = try await api.run(method: Users.Get(ids: ids)).map(User.init)
        } catch {
            logI { "getUsers failed error: \(error)" }
            throw GeneralError(apiError: error)
        }
        taskFactory.task {
            await self.offline.update(users: users)
        }
        logI { "getUsers OK" }
        return users
    }

    public func searchUsers(query: String) async throws(GeneralError) -> [User] {
        logI { "search users [q=\(query)]" }
        if query.isEmpty {
            logI { "search users query is empty, returning immediatly" }
            return []
        }
        let users: [User]
        do {
            users = try await api.run(method: Users.Search(query: query)).map(User.init)
        } catch {
            logI { "search users [q=\(query)] failed error: \(error)" }
            throw GeneralError(apiError: error)
        }
        taskFactory.task {
            await self.offline.update(users: users)
        }
        logI { "search users [q=\(query)] OK" }
        return users
    }
}

extension DefaultUsersRepository: Loggable {}
