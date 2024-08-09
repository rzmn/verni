import Foundation

struct UpdatePasswordState: Equatable {
    let oldPassword: String
    let newPassword: String
    let repeatNewPassword: String

    let newPasswordHint: String?
    let repeatNewPasswordHint: String?

    static var initial: Self {
        UpdatePasswordState(
            oldPassword: "",
            newPassword: "",
            repeatNewPassword: "",
            newPasswordHint: nil,
            repeatNewPasswordHint: nil
        )
    }
}
