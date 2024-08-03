public enum EmailValidationError: Error {
    case invalidFormat
    case alreadyTaken
    case other(GeneralError)
}

public protocol EmailValidationUseCase {
    func validateEmail(_ email: String) async -> Result<Void, EmailValidationError>
}
