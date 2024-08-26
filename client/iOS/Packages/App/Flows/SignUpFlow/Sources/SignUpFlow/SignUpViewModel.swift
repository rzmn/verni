import Foundation
import Combine
import Domain

@MainActor
class SignUpViewModel {
    @Published var state: SignUpState

    @Published var password: String
    @Published var passwordRepeat: String
    @Published var email: String
    @Published var passwordHint: String?
    @Published var passwordsMatch: Bool?
    @Published var emailHint: String?

    private let localEmailValidator: EmailValidationUseCase
    private let localPasswordValidator: PasswordValidationUseCase

    init(localEmailValidator: EmailValidationUseCase, localPasswordValidator: PasswordValidationUseCase) {
        let initial = SignUpState(
            email: "",
            password: "",
            passwordConfirmation: "",
            emailHint: nil,
            passwordHint: nil,
            passwordConfirmationHint: nil
        )
        state = initial

        password = initial.password
        passwordRepeat = initial.passwordConfirmation
        email = initial.email
        passwordHint = initial.passwordHint
        passwordsMatch = nil
        emailHint = initial.emailHint

        self.localEmailValidator = localEmailValidator
        self.localPasswordValidator = localPasswordValidator

        setupStateBuilder()
    }

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
        Publishers.CombineLatest($password, $passwordRepeat)
            .map { value -> Bool? in
                let (password, passwordRepeat) = value
                guard !password.isEmpty && !passwordRepeat.isEmpty else {
                    return nil
                }
                return password == passwordRepeat
            }
            .assign(to: &$passwordsMatch)

        let credentials = Publishers.CombineLatest3($email, $password, $passwordRepeat)
        let hints = Publishers.CombineLatest3($emailHint, $passwordHint, $passwordsMatch)
        Publishers.CombineLatest(credentials, hints)
            .map { value in
                let (credentials, hints) = value
                let (email, password, passwordRepeat) = credentials
                let (emailHint, passwordHint, passwordsMatchHint) = hints
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
                    }()
                )
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
