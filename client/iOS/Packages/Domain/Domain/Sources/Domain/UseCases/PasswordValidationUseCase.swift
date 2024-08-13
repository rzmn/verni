public enum PasswordValidationVerdict: Error {
    case invalid(message: String)
    case weak(message: String)
    case strong
}

public protocol PasswordValidationUseCase {
    func validatePassword(_ password: String) -> PasswordValidationVerdict
}
