public protocol ProfileOfflineMutableRepository: Sendable {
    func update(profile: Profile) async
}
