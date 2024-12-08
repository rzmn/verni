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
    public func getUser(id: User.Identifier) async -> User? {
        await persistency[Schemas.users.index(for: id)].flatMap(User.init)
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineMutableRepository {
    public func update(users: [User]) async {
        for user in users {
            await persistency.update(value: UserDto(domain: user), for: Schemas.users.index(for: user.id))
        }
    }
}
