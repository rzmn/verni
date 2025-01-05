import Foundation
import PersistentStorage
import Domain
internal import ApiDomainConvenience

public actor DefaultProfileOfflineRepository {
    private let persistency: Persistency

    public init(persistency: Persistency) {
        self.persistency = persistency
    }
}

extension DefaultProfileOfflineRepository: ProfileOfflineRepository {
    public func getProfile() async -> Profile? {
        await persistency[Schema.profile.unkeyed].flatMap(Profile.init)
    }
}

extension DefaultProfileOfflineRepository: ProfileOfflineMutableRepository {
    public func update(profile: Domain.Profile) async {
        await persistency.update(value: ProfileDto(domain: profile), for: Schema.profile.unkeyed)
        await persistency.update(value: UserDto(domain: profile.user), for: Schema.users.index(for: profile.user.id))
    }
}
