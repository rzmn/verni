import Entities
import AppLayer
import SwiftUICore
import AppBase
import SignUpScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
import DesignSystem
import Combine
internal import Convenience

@MainActor final class SignUpSideEffects: ActionHandler {
    private unowned let store: Store<SignUpState, SignUpAction<AnyHostedAppSession>>
    private unowned let session: SandboxAppSession
    private let authUseCase: any AuthUseCase<HostedDomainLayer>
    private let emailValidationUseCase: EmailValidationUseCase
    private let passwordValidationUseCase: PasswordValidationUseCase
    private let saveCredentialsUseCase: SaveCredendialsUseCase
    
    private var emailValidationSubject = PassthroughSubject<String, Never>()
    private var passwordValidationSubject = PassthroughSubject<String, Never>()
    private var passwordRepeatMatchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    var id: String {
        "\(SignUpSideEffects.self)"
    }

    init(
        store: Store<SignUpState, SignUpAction<AnyHostedAppSession>>,
        session: SandboxAppSession,
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase
    ) {
        self.store = store
        self.session = session
        self.authUseCase = authUseCase
        self.emailValidationUseCase = emailValidationUseCase
        self.passwordValidationUseCase = passwordValidationUseCase
        self.saveCredentialsUseCase = saveCredentialsUseCase
        resetValidationSubscriptions()
    }

    private func resetValidationSubscriptions() {
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
        emailValidationSubject = PassthroughSubject<String, Never>()
        passwordValidationSubject = PassthroughSubject<String, Never>()
        passwordRepeatMatchSubject = PassthroughSubject<String, Never>()
        
        emailValidationSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
            .store(in: &cancellables)
            
        passwordValidationSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] password in
                self?.validatePassword(password)
            }
            .store(in: &cancellables)
        
        passwordRepeatMatchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] repeatPassword in
                self?.validatePasswordMatch(repeatPassword)
            }
            .store(in: &cancellables)
    }

    func handle(_ action: SignUpAction<AnyHostedAppSession>) {
        switch action {
        case .passwordTextChanged(let text):
            passwordTextChanged(text: text)
        case .emailTextChanged(let text):
            emailTextChanged(text: text)
        case .passwordRepeatTextChanged(let text):
            passwordRepeatTextChanged(text: text)
        case .onSignUpTap:
            signUp()
        case .onTapBack, .signUp:
            resetValidationSubscriptions()
        default:
            break
        }
    }

    private func signUp() {
        let state = store.state
        guard state.canSubmitCredentials else {
            return
        }
        guard !state.signUpInProgress else {
            return
        }
        store.dispatch(.onSigningUpStarted)
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        Task {
            await doSignUp(credentials: credentials)
        }
    }

    private func doSignUp(credentials: Credentials) async {
        do {
            let session = await DefaultHostedAppSession(
                sandbox: session,
                session: try await authUseCase.signup(
                    credentials: credentials
                )
            )
            Task {
                await saveCredentialsUseCase.save(email: credentials.email, password: credentials.password)
            }
            store.dispatch(.signUp(AnyHostedAppSession(value: session)))
        } catch {
            switch error {
            case .noConnection:
                store.dispatch(
                    .onUpdateBottomSheet(
                        .noConnection(
                            onRetry: { [weak self] in
                                guard let self else { return }
                                store.dispatch(.onUpdateBottomSheet(nil))
                                signUp()
                            },
                            onClose: { [weak self] in
                                guard let self else { return }
                                store.dispatch(.onUpdateBottomSheet(nil))
                            }
                        )
                    )
                )
            default:
                store.dispatch(
                    .onUpdateBottomSheet(
                        .hint(title: "[debug] sign up failed", subtitle: "reason: \(error)", actionTitle: .sheetClose, action: { [weak self] in
                            guard let self else { return }
                            store.dispatch(.onUpdateBottomSheet(nil))
                        })
                    )
                )
            }
            store.dispatch(.onSigningUpFailed)
        }
    }
    
    private func emailTextChanged(text: String) {
        emailValidationSubject.send(text)
        checkCanSubmitCredentials(
            email: text,
            password: store.state.password,
            passwordRepeat: store.state.passwordRepeat
        )
    }
    
    private func passwordTextChanged(text: String) {
        passwordValidationSubject.send(text)
        checkCanSubmitCredentials(
            email: store.state.email,
            password: text,
            passwordRepeat: store.state.passwordRepeat
        )
    }
    
    private func passwordRepeatTextChanged(text: String) {
        passwordRepeatMatchSubject.send(text)
        checkCanSubmitCredentials(
            email: store.state.email,
            password: store.state.password,
            passwordRepeat: text
        )
    }
    
    private func checkCanSubmitCredentials(
        email: String,
        password: String,
        passwordRepeat: String
    ) {
        let emailValid: Bool
        do {
            try emailValidationUseCase.validateEmail(email)
            emailValid = true
        } catch {
            emailValid = false
        }
        let passwordValid: Bool
        switch passwordValidationUseCase.validatePassword(password) {
        case .invalid:
            passwordValid = false
        case .weak, .strong:
            passwordValid = true
        }
        let passwordsMatch = password == passwordRepeat
        store.dispatch(
            .canSubmitCredentialsChanged(
                emailValid && passwordValid && passwordsMatch
            )
        )
    }
    
    private func validateEmail(_ email: String) {
        do {
            try emailValidationUseCase.validateEmail(email)
            store.dispatch(.emailHintChanged(nil))
        } catch {
            if case EmailValidationError.isNotEmail = error {
                store.dispatch(.emailHintChanged(.invalidEmail))
            }
        }
    }
    
    private func validatePassword(_ password: String) {
        let verdict = passwordValidationUseCase.validatePassword(password)
        switch verdict {
        case .strong:
            store.dispatch(.passwordHintChanged(nil))
        case .weak:
            store.dispatch(.passwordHintChanged(.passwordWeak))
        case .invalid(let reason):
            switch reason {
            case .minimalCharacterCount(let count):
                store.dispatch(
                    .passwordHintChanged(
                        .passwordShouldHaveAtLeast(
                            charactersCount: count
                        )
                    )
                )
            case .hasInvalidCharacter(let found, _):
                store.dispatch(
                    .passwordHintChanged(
                        .passwordContainsInvalidCharacter(String(found))
                    )
                )
            }
        }
    }

    private func validatePasswordMatch(_ repeatPassword: String) {
        let password = store.state.password
        let matches = password == repeatPassword
        
        if !matches {
            store.dispatch(.passwordRepeatHintChanged(.passwordsDidNotMatch))
        } else {
            store.dispatch(.passwordRepeatHintChanged(nil))
        }
    }
}
