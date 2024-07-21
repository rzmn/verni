import Domain
import Api
import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultUsersRepository {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

extension DefaultUsersRepository: UsersRepository {
    public func getHostInfo() async -> Result<User, GeneralError> {
        switch await api.getMyInfo() {
        case .success(let dto):
            return .success(User(dto: dto))
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }

    public func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError> {
        switch await api.getUsers(uids: ids) {
        case .success(let dto):
            return .success(dto.map(User.init))
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
            return .success(dto.map(User.init))
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }
}
