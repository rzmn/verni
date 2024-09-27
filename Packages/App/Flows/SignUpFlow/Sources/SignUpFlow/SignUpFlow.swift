import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import DesignSystem
internal import ProgressHUD

actor SignUpFlow {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let store: Store<SignUpState, SignUpAction>

    private let haptic: HapticManager
    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var handler: (@MainActor (SignUpTerminationEvent) -> Void)?

    public init(di: DIContainer, haptic: HapticManager = DefaultHapticManager()) async {
        self.haptic = haptic
        authUseCase = await di.authUseCase()
        store = await Store(
            current: Self.initialState,
            reducer: Self.reducer
        )
    }
}

// MARK: - Flow

@MainActor extension SignUpFlow: SUIFlow {
    private func with(
        handler: @escaping @MainActor (SignUpTerminationEvent) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    @ViewBuilder
    func instantiate(handler: @escaping @MainActor (SignUpTerminationEvent) -> Void) -> SignUpView {
        SignUpView(
            store: store,
            actionsFactory: self.with(handler: handler)
        )
    }
}

// MARK: - Actions

@MainActor extension SignUpFlow: ActionsFactory {
    func action(_ kind: SignUpAction.Kind) -> SignUpAction {
        switch kind {
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
        case .confirmSignUp:
            confirmSignUp()
        case .closeSignUp:
            closeSignUp()
        }
    }

    private func emailTextChanged(text: String) -> SignUpAction {
        .action(kind: .emailTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordTextChanged(text: String) -> SignUpAction {
        .action(kind: .passwordTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordRepeatTextChanged(text: String) -> SignUpAction {
        .action(kind: .passwordRepeatTextChanged(text)) {
            // validation runs there
        }
    }

    private func showSnackbar(_ preset: Snackbar.Preset) -> SignUpAction {
        .action(kind: .showSnackbar(preset)) { [weak self] in
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

    private func hideSnackbar() -> SignUpAction {
        .action(kind: .hideSnackbar) { [weak self] in
            guard let self else { return }
            if let hideSnackbarTask {
                hideSnackbarTask.cancel()
            }
            hideSnackbarTask = nil
        }
    }

    private func spinner(running: Bool) -> SignUpAction {
        .action(kind: .spinner(running))
    }

    private func closeSignUp() -> SignUpAction {
        .action(kind: .closeSignUp) {
            self.handler?(.canceled)
        }
    }

    private func confirmSignUp() -> SignUpAction {
        .action(kind: .confirmSignUp) { [weak self] in
            guard let self else { return }
            let state = store.state
            guard state.canConfirm else {
                return haptic.errorHaptic()
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
            haptic.errorHaptic()
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
