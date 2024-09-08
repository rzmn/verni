public protocol UsersOfflineMutableRepository: Sendable {
    func update(users: [User]) async
}
