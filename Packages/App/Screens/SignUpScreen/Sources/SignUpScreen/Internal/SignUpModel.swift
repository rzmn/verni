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

    @MainActor private let emailSubject = PassthroughSubject<String, Never>()
    @MainActor private let passwordSubject = PassthroughSubject<String, Never>()
    @MainActor private let passwordRepeatSubject = PassthroughSubject<String, Never>()

    @MainActor private var hideSnackbarTask: Task<Void, Never>?
    @MainActor private var subscriptions = Set<AnyCancellable>()
    @MainActor private var handler: (@MainActor (SignUpEvent) -> Void)?

    init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
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
                do {
                    try di.appCommon.localEmailValidationUseCase.validateEmail(email)
                    return .isEmpty
                } catch {
                    return .message(.unacceptable(.l10n.auth.emailWrongFormat))
                }
            }
            .sink { value in
                self.store.with(self).dispatch(.emailHintUpdated(value))
            }
            .store(in: &subscriptions)
        passwordSubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map { password in
                if password.isEmpty {
                    return .isEmpty
                }
                switch di.appCommon.localPasswordValidationUseCase.validatePassword(password) {
                case .strong:
                    return .message(.acceptable(.l10n.auth.passwordIsStrong))
                case .weak:
                    return .message(.warning(.l10n.auth.passwordIsWeak))
                case .invalid:
                    return .message(.unacceptable(.l10n.auth.passwordWrongFormat))
                }
            }
            .sink { value in
                self.store.with(self).dispatch(.passwordHintUpdated(value))
            }
            .store(in: &subscriptions)
        Publishers.CombineLatest(passwordSubject, passwordRepeatSubject)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .map { password, passwordRepeat in
                if passwordRepeat.isEmpty {
                    return .isEmpty
                }
                if password == passwordRepeat {
                    return .noHint
                }
                return .message(.unacceptable(.l10n.auth.passwordRepeatDidNotMatch))
            }
            .sink { value in
                self.store.with(self).dispatch(.passwordRepeatHintUpdated(value))
            }
            .store(in: &subscriptions)
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
        case .emailHintUpdated(let hint):
            emailHintUpdated(hint: hint)
        case .passwordHintUpdated(let hint):
            passwordHintUpdated(hint: hint)
        case .passwordRepeatHintUpdated(let hint):
            passwordRepeatHintUpdated(hint: hint)
        case .spinner(let running):
            spinner(running: running)
        case .showSnackbar(let preset):
            showSnackbar(preset)
        case .hideSnackbar:
            hideSnackbar()
        case .confirmFailedFeedback:
            confirmFailedFeedback()
        case .confirm:
            confirm()
        }
    }

    private func emailTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .emailTextChanged(text)) {
            self.emailSubject.send(text)
        }
    }

    private func passwordTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordTextChanged(text)) {
            self.passwordSubject.send(text)
        }
    }

    private func passwordRepeatTextChanged(text: String) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordRepeatTextChanged(text)) {
            self.passwordRepeatSubject.send(text)
        }
    }

    private func emailHintUpdated(hint: SignUpState.CredentialHint) -> ActionExecutor<SignUpAction> {
        .make(action: .emailHintUpdated(hint))
    }

    private func passwordHintUpdated(hint: SignUpState.CredentialHint) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordHintUpdated(hint))
    }

    private func passwordRepeatHintUpdated(hint: SignUpState.CredentialHint) -> ActionExecutor<SignUpAction> {
        .make(action: .passwordRepeatHintUpdated(hint))
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

    private func confirmFailedFeedback() -> ActionExecutor<SignUpAction> {
        .make(action: .confirmFailedFeedback) {
            AppServices.default.haptic.errorHaptic()
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
                return store.dispatch(confirmFailedFeedback())
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
                store.dispatch(showSnackbar(.internalError("\(error)")))
            case .noConnection:
                store.dispatch(showSnackbar(.noConnection))
            case .other(let error):
                store.dispatch(showSnackbar(.internalError("\(error)")))
            }
        }
    }
}
