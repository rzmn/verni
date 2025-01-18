import Entities
import UsersRepository
import Api
import Logging
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
            if let noConnection = error.noConnection {
                throw .noConnection(noConnection)
            } else {
                throw .other(error)
            }
        }
        let users: [Components.Schemas.User]
        switch response {
        case .ok(let payload):
            switch payload.body {
            case .json(let json):
                users = json.response
            }
        case .unauthorized(let payload):
            throw .notAuthorized(ErrorContext(context: payload.apiError))
        case .internalServerError(let payload):
            throw .other(ErrorContext(context: payload.apiError))
        case .undocumented(statusCode: let statusCode, let payload):
            logE { "search users undocumented response code: \(statusCode), payload: \(payload)" }
            throw .other(ErrorContext(context: payload))
        }
        return users.compactMap { user in
            guard user.id == user.ownerId else {
                logE { "found sandbox user in search response \(user)" }
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
