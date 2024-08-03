public enum EmailUpdateError: Error {
    case validationError(EmailValidationError)
    case other(GeneralError)
}

public enum PasswordUpdateError: Error {
    case validationError(PasswordValidationError)
    case other(GeneralError)
}

public protocol ProfileEditingUseCase {
    func updateEmail(_ email: String) async -> Result<Void, EmailUpdateError>
    func updatePassword(old: String, new: String) async -> Result<Void, PasswordUpdateError>
}
