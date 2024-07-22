import Domain
import Api
import DataTransferObjects
import PersistentStorage
internal import ApiDomainConvenience

public class DefaultUsersRepository {
    private let api: Api
    private let persistency: Persistency

    public init(api: Api, persistency: Persistency) {
        self.api = api
        self.persistency = persistency
    }
}

extension DefaultUsersRepository: UsersRepository {
    public func getHostInfo() async -> Result<User, GeneralError> {
        switch await api.getMyInfo() {
        case .success(let dto):
            let user = User(dto: dto)
            Task.detached { [weak self] in
                guard let self else { return }
                await persistency.update(users: [user])
            }
            return .success(user)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }

    public func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError> {
        switch await api.getUsers(uids: ids) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await persistency.update(users: users)
            }
            return .success(users)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }

    public func searchUsers(query: String) async -> Result<[User], GeneralError> {
        if query.isEmpty {
            return .success([])
        }
        switch await api.searchUsers(query: query) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await persistency.update(users: users)
            }
            return .success(users)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }
}
