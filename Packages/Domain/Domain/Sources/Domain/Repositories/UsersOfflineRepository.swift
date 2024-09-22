public protocol UsersOfflineRepository: Sendable {
    func getUser(id: User.Identifier) async -> User?
}
