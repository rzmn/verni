import Foundation
import PersistentStorage
import Domain
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultUsersOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineRepository {
    public func getUser(id: User.ID) async -> User? {
        await persistency.user(id: id).flatMap(User.init)
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineMutableRepository {
    public func update(users: [User]) async {
        await persistency.update(users: users.map(UserDto.init))
    }
}
