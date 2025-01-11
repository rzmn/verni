import AsyncExtensions

public protocol UsersRepository: Sendable {
    var remote: UsersRemoteDataSource { get async }
    var updates: any AsyncBroadcast<[User.Identifier: User]> { get }

    subscript(id: User.Identifier) -> User? { get async }
    subscript(query: String) -> [User] { get async }

    func createUser(
        displayName: String
    ) async -> User

    func bind(
        localUserId: User.Identifier,
        to remoteUserId: User.Identifier
    ) async
    
    func updateDisplayName(
        userId: User.Identifier,
        displayName: String
    ) async
    
    func updateAvatar(
        userId: User.Identifier,
        base64Data: String
    ) async
}
