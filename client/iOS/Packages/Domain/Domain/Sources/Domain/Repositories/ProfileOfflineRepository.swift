public protocol ProfileOfflineRepository: Sendable {
    func getProfile() async -> Profile?
}
