import Foundation

public protocol UsersRepository {
    func getHostInfo() async -> Result<User, GeneralError>
    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError>
    func searchUsers(query: String) async -> Result<[User], GeneralError>
}
