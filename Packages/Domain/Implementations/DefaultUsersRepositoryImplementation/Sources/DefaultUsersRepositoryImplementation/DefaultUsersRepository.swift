import Domain
import Api
import Logging
import Base
import AsyncExtensions
internal import ApiDomainConvenience

public actor DefaultUsersRepository {
    public let logger: Logger
    private let api: APIProtocol
    private let offline: UsersOfflineMutableRepository
    private let taskFactory: TaskFactory

    public init(
        api: APIProtocol,
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
    public func getUsers(ids: [User.Identifier]) async throws(GeneralError) -> [User] {
        logI { "getUsers [\(ids.count) ids]" }
        if ids.isEmpty {
            logI { "get users query is empty, returning immediatly" }
            return []
        }
        let response: Operations.GetUsers.Output
        do {
            response = try await api.getUsers(
                .init(query: .init(ids: ids))
            )
        } catch {
            throw GeneralError(error)
        }
        let userDtos: [Components.Schemas.User]
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                userDtos = payload.response
            }
        case .unauthorized(let apiError):
            throw GeneralError(apiError)
        case .internalServerError(let apiError):
            throw GeneralError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on getUsers: \(statusCode) \(body)" }
            throw GeneralError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        let users = userDtos.map(User.init(dto:))
        taskFactory.detached {
            await self.offline.update(users: users)
        }
        logI { "getUsers ok" }
        return users
    }

    public func searchUsers(query: String) async throws(GeneralError) -> [User] {
        logI { "searchUsers [\(query)]" }
        if query.isEmpty {
            logI { "search users query is empty, returning immediatly" }
            return []
        }
        let response: Operations.SearchUsers.Output
        do {
            response = try await api.searchUsers(
                .init(query: .init(query: query))
            )
        } catch {
            throw GeneralError(error)
        }
        let userDtos: [Components.Schemas.User]
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                userDtos = payload.response
            }
        case .unauthorized(let apiError):
            throw GeneralError(apiError)
        case .internalServerError(let apiError):
            throw GeneralError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on searchUsers: \(statusCode) \(body)" }
            throw GeneralError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        let users = userDtos.map(User.init(dto:))
        taskFactory.detached {
            await self.offline.update(users: users)
        }
        logI { "getUsers ok" }
        return users
    }
}

extension DefaultUsersRepository: Loggable {}
