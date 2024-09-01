import Foundation

public enum EmailUpdateError: Error {
    case alreadyTaken
    case wrongFormat
    case other(GeneralError)
}

public enum PasswordUpdateError: Error {
    case validationError
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
    func updateEmail(_ email: String) async throws(EmailUpdateError)
    func updatePassword(old: String, new: String) async throws(PasswordUpdateError)

    func setAvatar(imageData: Data) async throws(SetAvatarError)
    func setDisplayName(_ displayName: String) async throws(SetDisplayNameError)
}
