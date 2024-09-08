import Combine

public protocol ProfileRepository: Sendable {
    @discardableResult
    func refreshProfile() async throws(GeneralError) -> Profile

    func profileUpdated() async -> AnyPublisher<Profile, Never>
}
