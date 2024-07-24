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

public enum CredentialsValidationError: Error {
    case tooShort(minAllowedLength: Int)
}

public protocol AuthUseCase {
    associatedtype AuthorizedSession
    func awake() async -> Result<AuthorizedSession, AwakeError>
    func login(credentials: Credentials) async -> Result<AuthorizedSession, LoginError>
    func signup(credentials: Credentials) async -> Result<AuthorizedSession, SignupError>

    func validateLogin(_ login: String) async -> Result<Void, CredentialsValidationError>
    func validatePassword(_ password: String) async -> Result<Void, CredentialsValidationError>
}
