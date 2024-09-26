import Foundation
import Combine
import Domain
import AppBase
internal import DesignSystem

@MainActor class SignUpViewModel: HapticManager {
    @Published var state: SignUpState

    @Published var password: String
    @Published var passwordRepeat: String
    @Published var email: String
    @Published var passwordHint: String?
    @Published var passwordsMatch: Bool?
    @Published var emailHint: String?
    @Published var isLoading: Bool
    @Published var snackbar: Snackbar.Preset?

    private var hideSnackbarTask: Task<Void, Never>?

    private let localEmailValidator: EmailValidationUseCase
    private let localPasswordValidator: PasswordValidationUseCase

    init(localEmailValidator: EmailValidationUseCase, localPasswordValidator: PasswordValidationUseCase) {
        let initial = SignUpState(
            email: "",
            password: "",
            passwordConfirmation: "",
            emailHint: nil,
            passwordHint: nil,
            passwordConfirmationHint: nil,
            isLoading: false,
            snackbar: nil
        )
        state = initial

        password = initial.password
        passwordRepeat = initial.passwordConfirmation
        email = initial.email
        passwordHint = initial.passwordHint
        passwordsMatch = nil
        emailHint = initial.emailHint
        isLoading = initial.isLoading
        snackbar = initial.snackbar

        self.localEmailValidator = localEmailValidator
        self.localPasswordValidator = localPasswordValidator

        setupStateBuilder()
    }

    func loading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func showSnackbar(_ snackbar: Snackbar.Preset) {
        if let hideSnackbarTask {
            hideSnackbarTask.cancel()
        }
        self.snackbar = snackbar
        hideSnackbarTask = Task { @MainActor in
            try? await Task.sleep(timeInterval: 3)
            if Task.isCancelled {
                return
            }
            hideSnackbar()
        }
    }

    func hideSnackbar() {
        if let hideSnackbarTask {
            hideSnackbarTask.cancel()
        }
        self.snackbar = nil
    }
}

// MARK: - Private

extension SignUpViewModel {
    private func setupEmailValidator() {
        $email
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map(localEmailValidator.validateEmail)
            .map { result -> String? in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    return error.message
                }
            }
            .assign(to: &$emailHint)
    }

    private func setupPasswordValidator() {
        $password
            .map(localPasswordValidator.validatePassword)
            .map { result -> String? in
                switch result {
                case .strong:
                    return nil
                case .weak(let message), .invalid(let message):
                    return message
                }
            }
            .assign(to: &$passwordHint)
    }

    private func setupPasswordRepeatMatchChecker() {
        Publishers.CombineLatest($password, $passwordRepeat)
            .map { value -> Bool? in
                let (password, passwordRepeat) = value
                guard !password.isEmpty && !passwordRepeat.isEmpty else {
                    return nil
                }
                return password == passwordRepeat
            }
            .assign(to: &$passwordsMatch)
    }

    private func setupStateBuilder() {
        setupEmailValidator()
        setupPasswordValidator()
        setupPasswordRepeatMatchChecker()
        let credentials = Publishers.CombineLatest3($email, $password, $passwordRepeat)
        let hints = Publishers.CombineLatest3($emailHint, $passwordHint, $passwordsMatch)
        let indicators = Publishers.CombineLatest($isLoading, $snackbar)
        Publishers.CombineLatest3(credentials, hints, indicators)
            .map { value in
                let (credentials, hints, indicators) = value
                let (email, password, passwordRepeat) = credentials
                let (emailHint, passwordHint, passwordsMatchHint) = hints
                let (isLoading, snackbar) = indicators
                return SignUpState(
                    email: email,
                    password: password,
                    passwordConfirmation: passwordRepeat,
                    emailHint: emailHint,
                    passwordHint: passwordHint,
                    passwordConfirmationHint: {
                        guard let passwordsMatchHint else {
                            return nil
                        }
                        if !passwordsMatchHint {
                            return "login_pwd_didnt_match".localized
                        } else {
                            return nil
                        }
                    }(),
                    isLoading: isLoading,
                    snackbar: snackbar
                )
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
