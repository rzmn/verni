import Foundation
import PersistentStorage
import Domain

public class DefaultUsersOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineRepository {
    public func getHostInfo() async -> User? {
        await persistency.getHostInfo()
    }
    
    public func getUser(id: User.ID) async -> User? {
        await persistency.user(id: id)
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineMutableRepository {
    public func update(users: [User]) async {
        await persistency.update(users: users)
    }
}
