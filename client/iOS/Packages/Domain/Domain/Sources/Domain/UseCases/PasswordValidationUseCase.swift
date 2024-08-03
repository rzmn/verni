public enum PasswordValidationError: Error {
    case tooShort(minAllowedLength: Int)
}

public protocol PasswordValidationUseCase {
    func validatePassword(_ password: String) async -> Result<Void, PasswordValidationError>
}
