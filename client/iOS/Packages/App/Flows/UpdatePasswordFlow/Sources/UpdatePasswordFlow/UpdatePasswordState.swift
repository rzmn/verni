import Foundation

struct UpdatePasswordState: Equatable {
    let oldPassword: String
    let newPassword: String
    let repeatNewPassword: String

    let newPasswordHint: String?
    let repeatNewPasswordHint: String?

    var canConfirm: Bool {
        if oldPassword.isEmpty || newPassword.isEmpty || repeatNewPassword.isEmpty {
            return false
        }
        if newPasswordHint != nil || repeatNewPasswordHint != nil {
            return false
        }
        return true
    }
}
