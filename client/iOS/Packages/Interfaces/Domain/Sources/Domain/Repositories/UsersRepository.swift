import Foundation

public enum AuthorizedSessionAquireFailureReason: Error {
    case noConnection
}

public protocol UsersRepository {
    func getHostInfo() async -> Result<User, RepositoryError>
    func getUsers(ids: [User.ID]) async -> Result<[User], RepositoryError>
    func searchUsers(query: String) async -> Result<[User], RepositoryError>
}
