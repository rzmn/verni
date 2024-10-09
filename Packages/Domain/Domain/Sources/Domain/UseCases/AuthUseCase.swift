import Foundation

public enum LoginError: Error, Sendable {
    case incorrectCredentials(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum SignupError: Error, Sendable {
    case alreadyTaken(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum AwakeError: Error, Sendable {
    case hasNoSession
    case internalError(Error)
}

public protocol AuthUseCase<AuthorizedSession>: Sendable {
    associatedtype AuthorizedSession: Sendable
    func awake() async throws(AwakeError) -> AuthorizedSession
    func login(credentials: Credentials) async throws(LoginError) -> AuthorizedSession
    func signup(credentials: Credentials) async throws(SignupError) -> AuthorizedSession
}
