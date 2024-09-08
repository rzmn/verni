import Foundation

public protocol UsersRepository: Sendable {
    func getUsers(ids: [User.ID]) async throws(GeneralError) -> [User]
    func searchUsers(query: String) async throws(GeneralError) -> [User]
}

public enum GetUserError: Error, Sendable {
    case noSuchUser
    case other(GeneralError)
}

public extension UsersRepository {
    func getUser(id: User.ID) async throws(GetUserError) -> User {
        let users: [User]
        do {
            users = try await getUsers(ids: [id])
        } catch {
            throw .other(error)
        }
        guard let user = users.first else {
            throw .noSuchUser
        }
        return user
    }
}
