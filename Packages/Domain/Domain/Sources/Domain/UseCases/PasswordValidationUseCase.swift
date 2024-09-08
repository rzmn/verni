public enum PasswordValidationVerdict: Error, Sendable {
    case invalid(message: String)
    case weak(message: String)
    case strong
}

public protocol PasswordValidationUseCase: Sendable {
    func validatePassword(_ password: String) -> PasswordValidationVerdict
}
