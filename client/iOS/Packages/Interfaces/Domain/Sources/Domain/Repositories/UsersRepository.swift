import Foundation

public enum AuthorizedSessionAquireFailureReason: Error {
    case noConnection
}

public protocol UsersRepository {
    func getHostInfo() async -> Result<User, GeneralError>
    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError>
    func searchUsers(query: String) async -> Result<[User], GeneralError>
}
