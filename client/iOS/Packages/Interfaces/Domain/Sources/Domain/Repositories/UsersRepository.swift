import Foundation

public protocol UsersRepository {
    func getHostInfo() async -> Result<User, GeneralError>
    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError>
    func searchUsers(query: String) async -> Result<[User], GeneralError>
}

public protocol UsersOfflineRepository {
    func getHostInfo() async -> User?
    func getUser(id: User.ID) async -> User?
}
