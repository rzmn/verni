import AsyncExtensions
import Entities

public enum BindUserError: Error {
    case notAllowed
    case userNotFound(User.Identifier)
    case `internal`(Error)
}

public enum UpdateDisplayNameError: Error {
    case notAllowed
    case tooShort
    case `internal`(Error)
}

public enum UpdateAvatarError: Error {
    case notAllowed
    case invalidImageData
    case `internal`(Error)
}

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
    ) async throws(BindUserError)
    
    func updateDisplayName(
        userId: User.Identifier,
        displayName: String
    ) async throws(UpdateDisplayNameError)
    
    func updateAvatar(
        userId: User.Identifier,
        base64Data: String
    ) async throws(UpdateAvatarError)
}
