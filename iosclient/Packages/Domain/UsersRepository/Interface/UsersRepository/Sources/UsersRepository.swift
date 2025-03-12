import AsyncExtensions
import Entities

public enum BindUserError: Error {
    case notAllowed
    case alreadyBound(to: User.Identifier)
    case userNotFound(User.Identifier)
    case `internal`(Error)
}

public enum UpdateDisplayNameError: Error {
    case notAllowed
    case userNotFound(User.Identifier)
    case tooShort
    case `internal`(Error)
}

public enum UpdateAvatarError: Error {
    case notAllowed
    case userNotFound(User.Identifier)
    case `internal`(Error)
}

public enum CreateUserError: Error {
    case nameTooShort
    case `internal`(Error)
}

public protocol UsersRepository: Sendable {
    var updates: any EventSource<[User.Identifier: AnyUser]> { get }

    subscript(id: User.Identifier) -> AnyUser? { get async }
    subscript(query: String) -> [AnyUser] { get async }
    
    func storeUserData(
        user: User
    ) async

    func createUser(
        displayName: String
    ) async throws(CreateUserError) -> User.Identifier

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
        imageId: Image.Identifier
    ) async throws(UpdateAvatarError)
}
