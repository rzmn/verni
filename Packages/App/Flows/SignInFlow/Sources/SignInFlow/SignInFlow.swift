import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import SignUpFlow
internal import DesignSystem
internal import ProgressHUD

public actor SignInFlow {
    private let viewModel: SignInViewModel
    private let signUpFlow: SignUpFlow
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let saveCredentials: SaveCredendialsUseCase

    public init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
        viewModel = await SignInViewModel(
            localEmailValidator: di.appCommon.localEmailValidationUseCase,
            passwordValidator: di.appCommon.localPasswordValidationUseCase
        )
        saveCredentials = di.appCommon.saveCredentialsUseCase
        self.signUpFlow = await SignUpFlow(di: di)
    }
}

// MARK: - Flow

extension SignInFlow: SUIFlow {

    @ViewBuilder @MainActor
    public func instantiate(handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void) -> some View {
        SignInView(
            store: Store<SignInState, SignInUserAction>(
                current: viewModel.state,
                publisher: viewModel.$state
            ) { [weak self] action in
                guard let self else { return }
                switch action {
                case .onEmailTextUpdated(let text):
                    viewModel.email = text
                case .onPasswordTextUpdated(let text):
                    viewModel.password = text
                case .onOpenSignInTap:
                    Task {
                        await self.openSignIn()
                    }
                case .onSignInTap:
                    Task {
                        await self.signIn(handler: handler)
                    }
                case .onSignInCloseTap:
                    Task {
                        await self.closeSignIn()
                    }
                case .onOpenSignUpTap:
                    viewModel.presentingSignUp = true
                case .onSignUpVisibilityUpdatedManually(let visible):
                    viewModel.presentingSignUp = visible
                }
            }
        ) {
            self.signUpFlow.instantiate { event in
                switch event {
                case .canceled:
                    self.viewModel.presentingSignUp = false
                case .created(let session):
                    handler(session)
                }
            }
        }
    }
}

// MARK: - Private

extension SignInFlow {
    private func signIn(handler: @escaping @MainActor (ActiveSessionDIContainer) -> Void) async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await viewModel.errorHaptic()
        }
        await viewModel.loading(true)
        do {
            let credentials = Credentials(
                email: state.email,
                password: state.password
            )
            let session = try await authUseCase.login(credentials: credentials)
            await saveCredentials.save(
                email: credentials.email,
                password: credentials.password
            )
            await handler(session)
        } catch {
            await viewModel.errorHaptic()
            switch error {
            case .incorrectCredentials:
                await viewModel.showSnackbar(.incorrectCredentials)
            case .wrongFormat:
                await viewModel.showSnackbar(.wrongFormat)
            case .noConnection:
                await viewModel.showSnackbar(.noConnection)
            case .other(let error):
                await viewModel.showSnackbar(.internalError("\(error)"))
            }
        }
    }

    private func openSignIn() async {
        await MainActor.run {
            viewModel.submitHaptic()
            viewModel.presentingSignIn = true
        }
    }

    private func closeSignIn() async {
        await MainActor.run {
            viewModel.presentingSignIn = false
        }
    }
}
