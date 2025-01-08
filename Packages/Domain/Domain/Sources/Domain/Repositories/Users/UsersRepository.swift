import AsyncExtensions

public protocol UsersRepository: Sendable {
    var remote: UsersRemoteDataSource { get async }

    subscript(id: User.Identifier) -> User? { get async }
    subscript(query: String) -> [User] { get async }

    func createUser(
        id: User.Identifier,
        displayName: String
    ) async -> User

    func bind(
        localUser: User.Identifier,
        to remoteUser: User.Identifier
    ) async
}
