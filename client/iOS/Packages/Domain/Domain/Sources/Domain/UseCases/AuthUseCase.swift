import Foundation

public enum LoginError: Error {
    case incorrectCredentials(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum SignupError: Error {
    case alreadyTaken(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum AwakeError: Error {
    case hasNoSession
}

public protocol AuthUseCase {
    associatedtype AuthorizedSession
    func awake() async throws(AwakeError) -> AuthorizedSession
    func login(credentials: Credentials) async throws(LoginError) -> AuthorizedSession
    func signup(credentials: Credentials) async throws(SignupError) -> AuthorizedSession
}
