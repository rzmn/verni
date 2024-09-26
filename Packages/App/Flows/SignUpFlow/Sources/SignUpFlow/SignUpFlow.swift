import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import DesignSystem
internal import ProgressHUD

public actor SignUpFlow {
    private let viewModel: SignUpViewModel
    private let authUseCase: any AuthUseCaseReturningActiveSession

    public init(di: DIContainer) async {
        authUseCase = await di.authUseCase()
        viewModel = await SignUpViewModel(
            localEmailValidator: di.appCommon.localEmailValidationUseCase,
            localPasswordValidator: di.appCommon.localPasswordValidationUseCase
        )
    }
}

// MARK: - Flow

extension SignUpFlow: SUIFlow {
    public enum TerminationEvent: Sendable {
        case canceled
        case created(ActiveSessionDIContainer)
    }

    @ViewBuilder @MainActor
    public func instantiate(handler: @escaping @MainActor (TerminationEvent) -> Void) -> some View {
        SignUpView(
            store: Store(
                current: self.viewModel.state,
                publisher: self.viewModel.$state
            ) { [weak self] action in
                guard let self else { return }
                switch action {
                case .onEmailTextUpdated(let text):
                    viewModel.email = text
                case .onPasswordTextUpdated(let text):
                    viewModel.password = text
                case .onRepeatPasswordTextUpdated(let text):
                    viewModel.passwordRepeat = text
                case .onSignInTap:
                    Task.detached {
                        await self.signIn(handler: handler)
                    }
                }
            }
        )
    }
}

// MARK: - Private

extension SignUpFlow {
    private func signIn(handler: @escaping @MainActor (TerminationEvent) -> Void) async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await viewModel.errorHaptic()
        }
        await viewModel.loading(true)
        do {
            let container = try await authUseCase.signup(
                credentials: Credentials(
                    email: state.email,
                    password: state.password
                )
            )
            return await handler(.created(container))
        } catch {
            await viewModel.errorHaptic()
            switch error {
            case .alreadyTaken:
                await viewModel.showSnackbar(.emailAlreadyTaken)
            case .wrongFormat:
                await viewModel.showSnackbar(.wrongFormat)
            case .noConnection:
                await viewModel.showSnackbar(.noConnection)
            case .other(let error):
                await viewModel.showSnackbar(.internalError("\(error)"))
            }
        }
    }
}
