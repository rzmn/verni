import Combine
import Domain
import DI
import Foundation
import AppBase
internal import DesignSystem

@MainActor final class SignInSideEffects: Sendable {
    private unowned let store: Store<SignInState, SignInAction>

    private let saveCredentialsUseCase: SaveCredendialsUseCase
    private let emailValidationUseCase: EmailValidationUseCase
    private let authUseCase: any AuthUseCaseReturningActiveSession

    private let emailSubject = PassthroughSubject<String, Never>()
    private var hideSnackbarTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private var handler: (@MainActor (SignInEvent) -> Void)?

    init(
        store: Store<SignInState, SignInAction>,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        emailValidationUseCase: EmailValidationUseCase,
        authUseCase: any AuthUseCaseReturningActiveSession
    ) {
        self.store = store
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.emailValidationUseCase = emailValidationUseCase
        self.authUseCase = authUseCase
        setupValidators()
    }

    private func setupValidators() {
        emailSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map { email in
                if email.isEmpty {
                    return .isEmpty
                }
                do {
                    try self.emailValidationUseCase.validateEmail(email)
                    return .isEmpty
                } catch {
                    return .message(.unacceptable(.l10n.auth.emailWrongFormat))
                }
            }
            .sink { value in
                self.store.dispatch(.emailHintUpdated(value))
            }
            .store(in: &subscriptions)
    }
}

extension SignInSideEffects: Middleware {
    var id: String {
        "\(Self.self)"
    }

    func handle(_ action: SignInAction) {
        switch action {
        case .emailTextChanged(let text):
            emailTextChanged(text: text)
        case .passwordTextChanged(let text):
            passwordTextChanged(text: text)
        case .emailHintUpdated(let hint):
            emailHintUpdated(hint: hint)
        case .spinner(let running):
            spinner(running: running)
        case .showSnackbar(let preset):
            showSnackbar(preset)
        case .hideSnackbar:
            hideSnackbar()
        case .confirm:
            confirm()
        case .createAccount:
            createAccount()
        case .confirmFailedFeedback:
            confirmFailedFeedback()
        case .close:
            close()
        }
    }

    private func emailTextChanged(text: String) {
        emailSubject.send(text)
    }

    private func passwordTextChanged(text: String) {
        // empty
    }

    private func emailHintUpdated(hint: SignInState.CredentialHint) {
        // empty
    }

    private func showSnackbar(_ preset: Snackbar.Preset) {
        if let hideSnackbarTask {
            hideSnackbarTask.cancel()
        }
        hideSnackbarTask = Task { @MainActor in
            try? await Task.sleep(timeInterval: 3)
            if Task.isCancelled {
                return
            }
            store.dispatch(.hideSnackbar)
        }
    }

    private func hideSnackbar() {
        if let hideSnackbarTask {
            hideSnackbarTask.cancel()
        }
        hideSnackbarTask = nil
    }

    private func spinner(running: Bool) {
        // empty
    }

    private func confirmFailedFeedback() {
        AppServices.default.haptic.errorHaptic()
    }

    private func createAccount() {
        handler?(.routeToSignUp)
    }

    private func close() {
        // empty
    }

    private func confirm() {
        let state = store.state
        guard state.canConfirm else {
            return store.dispatch(.confirmFailedFeedback)
        }
        Task.detached {
            await self.signIn(state: state)
        }
    }

    private func signIn(state: SignInState) async {
        store.dispatch(.spinner(true))
        do {
            let credentials = Credentials(
                email: state.email,
                password: state.password
            )
            let session = try await authUseCase.login(credentials: credentials)
            await saveCredentialsUseCase.save(
                email: credentials.email,
                password: credentials.password
            )
            store.dispatch(.spinner(false))
            handler?(.signedIn(session))
        } catch {
            store.dispatch(.spinner(false))
            switch error {
            case .incorrectCredentials:
                store.dispatch(.confirmFailedFeedback)
                store.dispatch(.showSnackbar(.incorrectCredentials))
            case .wrongFormat:
                store.dispatch(.confirmFailedFeedback)
                store.dispatch(.showSnackbar(.internalError("\(error)")))
            case .noConnection:
                store.dispatch(.showSnackbar(.noConnection))
            case .other(let error):
                store.dispatch(.showSnackbar(.internalError("\(error)")))
            }
        }
    }
}
