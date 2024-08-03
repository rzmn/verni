import Foundation
import PersistentStorage
import Domain
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultUsersOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineRepository {
    public func getHostInfo() async -> Profile? {
        await persistency.getHostInfo().flatMap(Profile.init)
    }
    
    public func getUser(id: User.ID) async -> User? {
        await persistency.user(id: id).flatMap(User.init)
    }
}

extension DefaultUsersOfflineRepository: UsersOfflineMutableRepository {
    public func updateHostInfo(info: Profile) async {
        await persistency.update(hostInfo: ProfileDto(domain: info))
        await persistency.update(users: [UserDto(domain: info.user)])
    }

    public func update(users: [User]) async {
        await persistency.update(users: users.map(UserDto.init))
    }
}
