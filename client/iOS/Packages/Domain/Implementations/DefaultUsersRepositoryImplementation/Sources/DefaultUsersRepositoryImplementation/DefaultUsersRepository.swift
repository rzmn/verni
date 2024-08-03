import Domain
import Api
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultUsersRepository {
    private let api: ApiProtocol
    private let offline: UsersOfflineMutableRepository

    public init(api: ApiProtocol, offline: UsersOfflineMutableRepository) {
        self.api = api
        self.offline = offline
    }
}

extension DefaultUsersRepository: UsersRepository {
    public func getHostInfo() async -> Result<Domain.Profile, GeneralError> {
        switch await api.run(method: Profile.GetInfo()) {
        case .success(let dto):
            let profile = Profile(dto: dto)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.updateHostInfo(info: profile)
            }
            return .success(profile)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }

    public func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError> {
        let method = Users.Get(parameters: .init(ids: ids))
        switch await api.run(method: method) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(users: users)
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
        let method = Users.Search(
            parameters: .init(query: query)
        )
        switch await api.run(method: method) {
        case .success(let dto):
            let users = dto.map(User.init)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(users: users)
            }
            return .success(users)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }
}
