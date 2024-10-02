import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import DesignSystem
internal import ProgressHUD

actor SignInModel {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let saveCredentialsUseCase: any SaveCredendialsUseCase
    private let store: Store<SignInState, SignInAction>

    @MainActor private let emailSubject = PassthroughSubject<String, Never>()

    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var subscriptions = Set<AnyCancellable>()
    @MainActor private var handler: (@MainActor (SignInEvent) -> Void)?

    init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
        saveCredentialsUseCase = di.appCommon.saveCredentialsUseCase
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await setupValidators(di: di)
    }

    @MainActor private func setupValidators(di: DIContainer) {
        emailSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map { email in
                if email.isEmpty {
                    return .isEmpty
                }
                switch di.appCommon.localEmailValidationUseCase.validateEmail(email) {
                case .success:
                    return .message(.acceptable("email ok"))
                case .failure(let error):
                    return .message(.unacceptable(error.message))
                }
            }
            .sink { value in
                self.store.with(self).dispatch(.emailHintUpdated(value))
            }
            .store(in: &subscriptions)
    }
}

// MARK: - Flow

@MainActor extension SignInModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (SignInEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(
        handler: @escaping @MainActor (SignInEvent) -> Void
    ) -> SignInView {
        SignInView(
            executorFactory: with(handler: handler),
            store: store
        )
    }
}

// MARK: - Actions

@MainActor extension SignInModel: ActionExecutorFactory {
    func executor(for action: SignInAction) -> ActionExecutor<SignInAction> {
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

    private func emailTextChanged(text: String) -> ActionExecutor<SignInAction> {
        .make(action: .emailTextChanged(text)) {
            self.emailSubject.send(text)
        }
    }

    private func passwordTextChanged(text: String) -> ActionExecutor<SignInAction> {
        .make(action: .passwordTextChanged(text))
    }

    private func emailHintUpdated(hint: SignInState.CredentialHint) -> ActionExecutor<SignInAction> {
        .make(action: .emailHintUpdated(hint))
    }

    private func showSnackbar(_ preset: Snackbar.Preset) -> ActionExecutor<SignInAction> {
        .make(action: .showSnackbar(preset)) { [weak self] in
            guard let self else { return }
            if let hideSnackbarTask {
                hideSnackbarTask.cancel()
            }
            hideSnackbarTask = Task { @MainActor in
                try? await Task.sleep(timeInterval: 3)
                if Task.isCancelled {
                    return
                }
                self.store.dispatch(hideSnackbar())
            }
        }
    }

    private func hideSnackbar() -> ActionExecutor<SignInAction> {
        .make(action: .hideSnackbar) { [weak self] in
            guard let self else { return }
            if let hideSnackbarTask {
                hideSnackbarTask.cancel()
            }
            hideSnackbarTask = nil
        }
    }

    private func spinner(running: Bool) -> ActionExecutor<SignInAction> {
        .make(action: .spinner(running))
    }

    private func confirmFailedFeedback() -> ActionExecutor<SignInAction> {
        .make(action: .confirmFailedFeedback) {
            AppServices.default.haptic.errorHaptic()
        }
    }

    private func createAccount() -> ActionExecutor<SignInAction> {
        .make(action: .createAccount) {
            self.handler?(.routeToSignUp)
        }
    }

    private func close() -> ActionExecutor<SignInAction> {
        .make(action: .close) {
            self.handler?(.canceled)
        }
    }

    private func confirm() -> ActionExecutor<SignInAction> {
        .make(action: .confirm) { [weak self] in
            guard let self else { return }
            let state = store.state
            guard state.canConfirm else {
                return store.dispatch(confirmFailedFeedback())
            }
            Task.detached {
                await self.signIn(state: state)
            }
        }
    }

    private func signIn(state: SignInState) async {
        store.dispatch(spinner(running: true))
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
            store.dispatch(spinner(running: false))
            handler?(.signedIn(session))
        } catch {
            store.dispatch(spinner(running: false))
            switch error {
            case .incorrectCredentials:
                store.dispatch(confirmFailedFeedback())
                store.dispatch(showSnackbar(.incorrectCredentials))
            case .wrongFormat:
                store.dispatch(confirmFailedFeedback())
                store.dispatch(showSnackbar(.wrongFormat))
            case .noConnection:
                store.dispatch(showSnackbar(.noConnection))
            case .other(let error):
                store.dispatch(showSnackbar(.internalError("\(error)")))
            }
        }
    }
}
