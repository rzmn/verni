import Foundation

public protocol UsersRepository {
    func getHostInfo() async -> Result<Profile, GeneralError>
    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError>
    func searchUsers(query: String) async -> Result<[User], GeneralError>
}

public protocol UsersOfflineRepository {
    func getHostInfo() async -> Profile?
    func getUser(id: User.ID) async -> User?
}

public protocol UsersOfflineMutableRepository: UsersOfflineRepository {
    func updateHostInfo(info: Profile) async
    func update(users: [User]) async
}
