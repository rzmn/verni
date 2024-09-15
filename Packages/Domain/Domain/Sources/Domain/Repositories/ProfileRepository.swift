public protocol ProfileRepository: Sendable {
    @discardableResult
    func refreshProfile() async throws(GeneralError) -> Profile
    func profileUpdated() async -> any CancellableStream<Profile>
}
