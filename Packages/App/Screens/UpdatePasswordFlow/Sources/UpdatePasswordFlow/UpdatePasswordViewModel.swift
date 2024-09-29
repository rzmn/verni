import Foundation
import Combine
import Domain

@MainActor class UpdatePasswordViewModel {
    @Published var state: UpdatePasswordState

    @Published var oldPassword: String
    @Published var newPassword: String
    @Published var repeatNewPassword: String
    @Published var newPasswordHint: String?
    @Published var repeatNewPasswordHint: String?

    private let passwordValidation: PasswordValidationUseCase

    init(passwordValidation: PasswordValidationUseCase) {
        let initial = UpdatePasswordState(
            oldPassword: "",
            newPassword: "",
            repeatNewPassword: "",
            newPasswordHint: nil,
            repeatNewPasswordHint: nil
        )
        state = initial
        oldPassword = initial.oldPassword
        newPassword = initial.newPassword
        repeatNewPassword = initial.repeatNewPassword
        newPasswordHint = initial.newPasswordHint
        repeatNewPasswordHint = initial.newPasswordHint

        self.passwordValidation = passwordValidation

        setupStateBuilder()
    }

    private func setupStateBuilder() {
        Publishers.CombineLatest($newPassword, $repeatNewPassword)
            .map { password, repeatPassword in
                if repeatPassword.isEmpty {
                    return true
                }
                return password == repeatPassword
            }
            .map { (matches: Bool) -> String? in
                if matches {
                    return nil
                } else {
                    return "password_repeat_did_not_match".localized
                }
            }
            .assign(to: &$repeatNewPasswordHint)

        $newPassword
            .map(passwordValidation.validatePassword)
            .map { result -> String? in
                switch result {
                case .strong:
                    return nil
                case .weak(let message), .invalid(let message):
                    return message
                }
            }
            .assign(to: &$newPasswordHint)

        let textFields = Publishers.CombineLatest3($oldPassword, $newPassword, $repeatNewPassword)
        let hints = Publishers.CombineLatest($newPasswordHint, $repeatNewPasswordHint)
        Publishers.CombineLatest(textFields, hints)
            .map { value in
                let (textFields, hints) = value
                let (oldPassword, newPassword, repeatNewPassword) = textFields
                let (newPasswordHint, repeatNewPasswordHint) = hints
                return UpdatePasswordState(
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                    repeatNewPassword: repeatNewPassword,
                    newPasswordHint: newPasswordHint,
                    repeatNewPasswordHint: repeatNewPasswordHint
                )
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
