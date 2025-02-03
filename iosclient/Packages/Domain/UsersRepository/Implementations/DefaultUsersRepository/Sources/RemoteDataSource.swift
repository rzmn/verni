import Entities
import UsersRepository
import Api
import Logging
internal import EntitiesApiConvenience
internal import Convenience

final class RemoteDataSource: Sendable {
    let logger: Logger
    private let api: APIProtocol
    
    init(
        api: APIProtocol,
        logger: Logger
    ) {
        self.api = api
        self.logger = logger
    }
}

extension RemoteDataSource: UsersRemoteDataSource {
    func searchUsers(
        query: String
    ) async throws(GeneralError) -> [User] {
        let response: Operations.SearchUsers.Output
        do {
            response = try await api.searchUsers(
                .init(
                    query: .init(
                        query: query
                    )
                )
            )
        } catch {
            throw GeneralError(error: error)
        }
        let users: [Components.Schemas.User]
        do {
            users = []
            _ = try response.get()
            assertionFailure("not implemented")
        } catch {
            switch error {
            case .expected(let error):
                logW { "search users finished with error: \(error)" }
                throw GeneralError(error: error)
            case .undocumented(let statusCode, let payload):
                logE { "search users undocumented response code: \(statusCode), payload: \(payload)" }
                throw GeneralError(error: error)
            }
        }
        return users.compactMap { user in
            guard user.id == user.ownerId else {
                logW { "found sandbox user in search response \(user)" }
                return nil
            }
            return User(
                id: user.id,
                payload: UserPayload(
                    displayName: user.displayName,
                    avatar: user.avatarId
                )
            )
        }
    }
}

extension RemoteDataSource: Loggable {}
