import Foundation
import Combine

public protocol ProfileRepository {
    @discardableResult
    func refreshProfile() async throws(GeneralError) -> Profile

    func profileUpdated() async -> AnyPublisher<Profile, Never>
}

public protocol ProfileOfflineRepository {
    func getProfile() async -> Profile?
}

public protocol ProfileOfflineMutableRepository {
    func update(profile: Profile) async
}
