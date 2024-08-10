import Foundation

public enum EmailUpdateError: Error {
    case validationError(EmailValidationError)
    case other(GeneralError)
}

public enum PasswordUpdateError: Error {
    case validationError(PasswordValidationError)
    case incorrectOldPassword
    case other(GeneralError)
}

public enum SetAvatarError: Error {
    case wrongFormat
    case other(GeneralError)
}

public enum SetDisplayNameError: Error {
    case wrongFormat
    case other(GeneralError)
}

public protocol ProfileEditingUseCase {
    func updateEmail(_ email: String) async -> Result<Void, EmailUpdateError>
    func updatePassword(old: String, new: String) async -> Result<Void, PasswordUpdateError>

    func setAvatar(imageData: Data) async -> Result<Void, SetAvatarError>
    func setDisplayName(_ displayName: String) async -> Result<Void, SetDisplayNameError>
}
