import Domain
import Api
import Logging
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultUsersRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let offline: UsersOfflineMutableRepository

    public init(api: ApiProtocol, logger: Logger, offline: UsersOfflineMutableRepository) {
        self.api = api
        self.logger = logger
        self.offline = offline
    }
}

extension DefaultUsersRepository: UsersRepository {
    public func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError> {
        logI { "getUsers [\(ids.count) ids]" }
        let method = Users.Get(ids: ids)
        switch await api.run(method: method) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(users: users)
            }
            logI { "getUsers OK" }
            return .success(users)
        case .failure(let error):
            logI { "getUsers failed error: \(error)" }
            return .failure(GeneralError(apiError: error))
        }
    }

    public func searchUsers(query: String) async -> Result<[User], GeneralError> {
        logI { "search users [q=\(query)]" }
        if query.isEmpty {
            logI { "search users query is empty, returning immediatly" }
            return .success([])
        }
        let method = Users.Search(query: query)
        switch await api.run(method: method) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(users: users)
            }
            logI { "search users [q=\(query)] OK" }
            return .success(users)
        case .failure(let error):
            logI { "search users [q=\(query)] failed error: \(error)" }
            return .failure(GeneralError(apiError: error))
        }
    }
}

extension DefaultUsersRepository: Loggable {}
