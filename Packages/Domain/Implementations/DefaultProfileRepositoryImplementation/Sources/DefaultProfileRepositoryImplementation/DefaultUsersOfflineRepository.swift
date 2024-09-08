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
        await persistency.getHostInfo().flatMap(Profile.init)
    }
}

extension DefaultProfileOfflineRepository: ProfileOfflineMutableRepository {
    public func update(profile: Domain.Profile) async {
        await persistency.update(hostInfo: ProfileDto(domain: profile))
        await persistency.update(users: [UserDto(domain: profile.user)])
    }
}
