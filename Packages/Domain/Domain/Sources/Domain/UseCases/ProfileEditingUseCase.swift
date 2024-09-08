import Foundation

public enum EmailUpdateError: Error, Sendable {
    case alreadyTaken
    case wrongFormat
    case other(GeneralError)
}

public enum PasswordUpdateError: Error, Sendable {
    case validationError
    case incorrectOldPassword
    case other(GeneralError)
}

public enum SetAvatarError: Error, Sendable {
    case wrongFormat
    case other(GeneralError)
}

public enum SetDisplayNameError: Error, Sendable {
    case wrongFormat
    case other(GeneralError)
}

public protocol ProfileEditingUseCase: Sendable {
    func updateEmail(_ email: String) async throws(EmailUpdateError)
    func updatePassword(old: String, new: String) async throws(PasswordUpdateError)

    func setAvatar(imageData: Data) async throws(SetAvatarError)
    func setDisplayName(_ displayName: String) async throws(SetDisplayNameError)
}
