import Domain
import Api
internal import ApiDomainConvenience

public class DefaultAuthorizedSessionRepository {
    private let api: Api

    public init(api: Api) {
        self.api = api
    }
}

private extension UserDto {
    var domain: User {
        User(id: login, status: {
            switch friendStatus {
            case .no:
                return .no
            case .incomingRequest:
                return .incoming
            case .outgoingRequest:
                return .outgoing
            case .friends:
                return .friend
            case .me:
                return .me
            }
        }())
    }
}

extension DefaultAuthorizedSessionRepository: UsersRepository {
    public func getHostInfo() async -> Result<User, RepositoryError> {
        switch await api.getMyInfo() {
        case .success(let dto):
            return .success(dto.domain)
        case .failure(let error):
            return .failure(RepositoryError(apiError: error))
        }
    }

    public func getUsers(ids: [User.ID]) async -> Result<[User], RepositoryError> {
        switch await api.getUsers(uids: ids) {
        case .success(let dto):
            return .success(dto.map(\.domain))
        case .failure(let error):
            return .failure(RepositoryError(apiError: error))
        }
    }

    public func searchUsers(query: String) async -> Result<[User], RepositoryError> {
        if query.isEmpty {
            return .success([])
        }
        switch await api.searchUsers(query: query) {
        case .success(let dto):
            return .success(dto.map(\.domain))
        case .failure(let error):
            return .failure(RepositoryError(apiError: error))
        }
    }
}
