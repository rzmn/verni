public protocol UsersOfflineRepository: Sendable {
    func getUser(id: User.ID) async -> User?
}
