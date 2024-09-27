import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import SignUpFlow
internal import DesignSystem
internal import ProgressHUD

actor SignInFlow {
    private let di: DIContainer
    private let signUpFlow: any SUIFlow<SignUpTerminationEvent, SignUpView>
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let store: Store<SignInState, SignInAction>

    private let haptic: HapticManager
    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var handler: (@MainActor (ActiveSessionDIContainer) -> Void)?

    init(
        di: DIContainer,
        haptic: HapticManager,
        signUpFlowFactory: SignUpFlowFactory
    ) async {
        self.di = di
        self.haptic = haptic
        authUseCase = await di.authUseCase()
        signUpFlow = await signUpFlowFactory.create()
        store = await Store(
            current: Self.initialState,
            reducer: Self.reducer
        )
    }
}

// MARK: - Flow

@MainActor extension SignInFlow: SUIFlow {
    private func with(
        handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void
    ) -> Self {
        self.handler = handler
        return self
    }

    @ViewBuilder func instantiate(
        handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void
    ) -> SignInView {
        SignInView(store: store, actionsFactory: self.with(handler: handler)) {
            AnyView(
                self.signUpFlow.instantiate { event in
                    switch event {
                    case .canceled:
                        self.store.dispatch(self.action(.closeSignUpCredentialsForm))
                    case .created(let session):
                        handler(session)
                    }
                }
            )
        }
    }
}

// MARK: - Actions

@MainActor extension SignInFlow: ActionsFactory {
    func action(_ kind: SignInAction.Kind) -> SignInAction {
        switch kind {
        case .openSignInCredentialsForm:
            openSignInCredentialsForm()
        case .closeSignInCredentialsForm:
            closeSignInCredentialsForm()
        case .signInCredentialsFormVisible(let visible):
            signInCredentialsFormVisible(visible: visible)
        case .openSignUpCredentialsForm:
            openSignUpCredentialsForm()
        case .closeSignUpCredentialsForm:
            closeSignUpCredentialsForm()
        case .signUpCredentialsFormVisible(let visible):
            signUpCredentialsFormVisible(visible: visible)
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
        case .confirmSignIn:
            confirmSignIn()
        }
    }

    private func openSignInCredentialsForm() -> SignInAction {
        .action(kind: .openSignInCredentialsForm) {
            self.store.dispatch(self.signInCredentialsFormVisible(visible: true))
        }
    }

    private func closeSignInCredentialsForm() -> SignInAction {
        .action(kind: .openSignInCredentialsForm) {
            self.store.dispatch(self.signInCredentialsFormVisible(visible: false))
        }
    }

    private func signInCredentialsFormVisible(visible: Bool) -> SignInAction {
        .action(kind: .signInCredentialsFormVisible(visible: visible))
    }

    private func signUpCredentialsFormVisible(visible: Bool) -> SignInAction {
        .action(kind: .signUpCredentialsFormVisible(visible: visible))
    }

    private func openSignUpCredentialsForm() -> SignInAction {
        .action(kind: .openSignUpCredentialsForm) {
            self.store.dispatch(self.signUpCredentialsFormVisible(visible: true))
        }
    }

    private func closeSignUpCredentialsForm() -> SignInAction {
        .action(kind: .openSignUpCredentialsForm) {
            self.store.dispatch(self.signUpCredentialsFormVisible(visible: false))
        }
    }

    private func emailTextChanged(text: String) -> SignInAction {
        .action(kind: .emailTextChanged(text)) {
            // validation runs there
        }
    }

    private func passwordTextChanged(text: String) -> SignInAction {
        .action(kind: .passwordTextChanged(text)) {
            // validation runs there
        }
    }

    private func showSnackbar(_ preset: Snackbar.Preset) -> SignInAction {
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

    private func hideSnackbar() -> SignInAction {
        .action(kind: .hideSnackbar) { [weak self] in
            guard let self else { return }
            if let hideSnackbarTask {
                hideSnackbarTask.cancel()
            }
            hideSnackbarTask = nil
        }
    }

    private func spinner(running: Bool) -> SignInAction {
        .action(kind: .spinner(running))
    }

    private func confirmSignIn() -> SignInAction {
        .action(kind: .confirmSignIn) { [weak self] in
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
            handler?(session)
        } catch {
            store.dispatch(spinner(running: false))
            haptic.errorHaptic()
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
