import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import DesignSystem
internal import ProgressHUD

actor SignUpModel {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let store: Store<SignUpState, SignUpAction>

    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var handler: (@MainActor (SignUpEvent) -> Void)?

    init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

// MARK: - ScreenProvider

@MainActor extension SignUpModel: ScreenProvider {
    private func with(
        handler: @escaping @MainActor (SignUpEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    func instantiate(handler: @escaping @MainActor (SignUpEvent) -> Void) -> SignUpView {
        SignUpView(
            store: store,
            executorFactory: with(handler: handler)
        )
    }
}

// MARK: - Actions

@MainActor extension SignUpModel: ActionExecutorFactory {
    func executor(for action: SignUpAction) -> ActionExecutor<SignUpAction> {
        switch action {
        case .emailTextChanged(let text):
            emailTextChanged(text: text)
        case .passwordTextChanged(let text):
            passwordTextChanged(text: text)
        case .passwordRepeatTextChanged(let text):
            passwordRepeatTextChanged(text: text)
        case .spinner(let running):
            spinner(running: running)
        case .showSnackbar(let preset):
            showSnackbar(preset)
        case .hideSnackbar:
            hideSnackbar()
        case .confirm:
            confirm()
        }
    }

    private func emailTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .emailTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordRepeatTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordRepeatTextChanged(text)) {
            // validation runs there
        }
    }

    private func showSnackbar(_ preset: Snackbar.Preset) -> ActionExecutor<SignUpAction> {
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

    private func hideSnackbar() -> ActionExecutor<SignUpAction> {
        .make(action: .hideSnackbar) { [weak self] in
            guard let self else { return }
            if let hideSnackbarTask {
                hideSnackbarTask.cancel()
            }
            hideSnackbarTask = nil
        }
    }

    private func spinner(running: Bool) -> ActionExecutor<SignUpAction> {
        .make(action: .spinner(running))
    }

    private func confirm() -> ActionExecutor<SignUpAction> {
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

    private func signIn(state: SignUpState) async {
        store.dispatch(spinner(running: true))
        do {
            let container = try await authUseCase.signup(
                credentials: Credentials(
                    email: state.email,
                    password: state.password
                )
            )
            store.dispatch(spinner(running: false))
            handler?(.created(container))
        } catch {
            store.dispatch(spinner(running: false))
            AppServices.default.haptic.errorHaptic()
            switch error {
            case .alreadyTaken:
                store.dispatch(showSnackbar(.emailAlreadyTaken))
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
