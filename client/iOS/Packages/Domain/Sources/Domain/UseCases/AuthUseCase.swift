import Foundation

public enum LoginFailureReason: Error {
    case incorrectCredentials(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum SignupFailureReason: Error {
    case alreadyTaken(Error)
    case wrongFormat(Error)
    case noConnection(Error)
    case other(Error)
}

public enum AwakeFailureReason: Error {
    case sessionExpired(Error)
    case hasNoSession
    case noConnection(Error)
    case other(Error)
}

public enum ValidationFailureReason: Error {
    case tooShort(minAllowedLength: Int)
}

public protocol AuthUseCase {
    associatedtype AuthorizedSession

    func awake() async -> Result<AuthorizedSession, AwakeFailureReason>
    func login(credentials: Credentials) async -> Result<AuthorizedSession, LoginFailureReason>
    func signup(credentials: Credentials) async -> Result<AuthorizedSession, SignupFailureReason>

    func validateLogin(_ login: String) async -> Result<Void, ValidationFailureReason>
    func validatePassword(_ password: String) async -> Result<Void, ValidationFailureReason>
}
