import Foundation
import Combine
import Domain

@MainActor
class SignInViewModel {
    @Published var state: SignInState

    @Published var password: String
    @Published var email: String
    @Published var emailHint: String?

    private let localEmailValidator: EmailValidationUseCase
    private let passwordValidator: PasswordValidationUseCase

    init(localEmailValidator: EmailValidationUseCase, passwordValidator: PasswordValidationUseCase) {
        let initial = SignInState(email: "", password: "", emailHint: nil)
        state = initial
        email = initial.email
        emailHint = initial.emailHint
        password = initial.password
        
        self.localEmailValidator = localEmailValidator
        self.passwordValidator = passwordValidator

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

        Publishers.CombineLatest3($email, $password, $emailHint)
            .map { value in
                SignInState(email: value.0, password: value.1, emailHint: value.2)
            }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: &$state)
    }
}
