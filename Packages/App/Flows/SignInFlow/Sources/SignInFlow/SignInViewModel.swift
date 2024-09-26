import Foundation
import Combine
import Domain
import AppBase
internal import DesignSystem

@MainActor class SignInViewModel: HapticManager {
    @Published var state: SignInState

    @Published var password: String
    @Published var email: String
    @Published var emailHint: String?
    @Published var presentingSignIn: Bool
    @Published var presentingSignUp: Bool

    @Published var isLoading: Bool
    @Published var snackbar: Snackbar.Preset?

    private var hideSnackbarTask: Task<Void, Never>?

    private let localEmailValidator: EmailValidationUseCase
    private let passwordValidator: PasswordValidationUseCase

    init(localEmailValidator: EmailValidationUseCase, passwordValidator: PasswordValidationUseCase) {
        let initial = SignInState(
            email: "",
            password: "",
            emailHint: nil,
            presentingSignUp: false,
            presentingSignIn: false,
            isLoading: false,
            snackbar: nil
        )
        state = initial
        email = initial.email
        emailHint = initial.emailHint
        password = initial.password
        isLoading = initial.isLoading
        snackbar = initial.snackbar
        presentingSignUp = initial.presentingSignUp
        presentingSignIn = initial.presentingSignIn

        self.localEmailValidator = localEmailValidator
        self.passwordValidator = passwordValidator

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

extension SignInViewModel {
    private func setupStateBuilder() {
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

        let state = Publishers.CombineLatest3($email, $password, $emailHint)
        let indicators = Publishers.CombineLatest4($presentingSignIn, $presentingSignUp, $isLoading, $snackbar)
        Publishers.CombineLatest(state, indicators)
            .map { value in
                let (state, indicators) = value
                let (email, password, emailHint) = state
                let (presentingSignIn, presentingSignUp, isLoading, snackbar) = indicators
                return SignInState(
                    email: email,
                    password: password,
                    emailHint: emailHint,
                    presentingSignUp: presentingSignUp,
                    presentingSignIn: presentingSignIn,
                    isLoading: isLoading,
                    snackbar: snackbar
                )
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
