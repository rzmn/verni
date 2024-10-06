public enum EmailValidationError: Error, Sendable {
    case isNotEmail
}

public protocol EmailValidationUseCase: Sendable {
    func validateEmail(_ email: String) throws(EmailValidationError)
}
