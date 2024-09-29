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
    private let di: DIContainer
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let store: Store<SignInState, SignInAction>

    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var handler: (@MainActor (SignInEvent) -> Void)?

    init(di: DIContainer) async {
        self.di = di
        authUseCase = await di.authUseCase()
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
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
        case .close:
            close()
        }
    }

    private func emailTextChanged(text: String) -> ActionExecutor<SignInAction> {
        .make(action: .emailTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordTextChanged(text: String) -> ActionExecutor<SignInAction> {
        .make(action: .passwordTextChanged(text)) {
            // validation runs there
        }
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
                return AppServices.default.haptic.errorHaptic()
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
            await di.appCommon.saveCredentialsUseCase.save(
                email: credentials.email,
                password: credentials.password
            )
            store.dispatch(spinner(running: false))
            handler?(.signedIn(session))
        } catch {
            store.dispatch(spinner(running: false))
            AppServices.default.haptic.errorHaptic()
            switch error {
            case .incorrectCredentials:
                store.dispatch(showSnackbar(.incorrectCredentials))
            case .wrongFormat:
                store.dispatch(showSnackbar(.wrongFormat))
            case .noConnection:
                store.dispatch(showSnackbar(.noConnection))
            case .other(let error):
                store.dispatch(showSnackbar(.internalError("\(error)")))
            }
        }
    }
}
