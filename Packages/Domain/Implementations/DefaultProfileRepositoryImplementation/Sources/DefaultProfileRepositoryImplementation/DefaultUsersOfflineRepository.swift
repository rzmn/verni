import Foundation
import PersistentStorage
import Domain
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultProfileOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultProfileOfflineRepository: ProfileOfflineRepository {
    public func getProfile() async -> Profile? {
        await persistency[Schemas.profile.unkeyedIndex].flatMap(Profile.init)
    }
}

extension DefaultProfileOfflineRepository: ProfileOfflineMutableRepository {
    public func update(profile: Domain.Profile) async {
        await persistency.update(value: ProfileDto(domain: profile), for: Schemas.profile.unkeyedIndex)
        await persistency.update(value: UserDto(domain: profile.user), for: Schemas.users.index(for: profile.user.id))
    }
}
