import Foundation

public protocol UsersRepository {
    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError>
    func searchUsers(query: String) async -> Result<[User], GeneralError>
}

public protocol UsersOfflineRepository {
    func getUser(id: User.ID) async -> User?
}

public protocol UsersOfflineMutableRepository: UsersOfflineRepository {
    func update(users: [User]) async
}
