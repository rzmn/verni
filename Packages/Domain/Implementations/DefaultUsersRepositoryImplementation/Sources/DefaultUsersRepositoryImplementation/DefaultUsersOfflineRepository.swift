import Foundation
import PersistentStorage
import Domain
import Api
internal import ApiDomainConvenience

public actor DefaultUsersOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineRepository {
    public func getUser(id: User.Identifier) async -> User? {
        await persistency[Schema.users.index(for: id)]
            .flatMap(User.init(dto:))
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineMutableRepository {
    public func update(users: [User]) async {
        for user in users.map(Components.Schemas.User.init(domain:)) {
            await persistency.update(value: user, for: Schema.users.index(for: user.id))
        }
    }
}
