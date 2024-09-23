import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
internal import DesignSystem
internal import ProgressHUD

public actor SignUpFlow {
    private lazy var presenter = AsyncLazyObject {
        SignUpPresenter(
            router: self.router,
            actions: await MainActor.run {
                self.makeActions()
            }
        )
    }
    private let viewModel: SignUpViewModel
    private var subscriptions = Set<AnyCancellable>()
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let router: AppRouter
    private var flowContinuation: Continuation?

    public init(di: DIContainer, router: AppRouter) async {
        self.router = router
        authUseCase = await di.authUseCase()
        viewModel = await SignUpViewModel(
            localEmailValidator: di.appCommon.localEmailValidationUseCase,
            localPasswordValidator: di.appCommon.localPasswordValidationUseCase
        )
    }
}

// MARK: - Flow

extension SignUpFlow: Flow {
    public enum TerminationEvent: Sendable {
        case canceled
        case created(ActiveSessionDIContainer)
    }

    public func perform() async -> TerminationEvent {
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
            Task.detached {
                await self.startFlow()
            }
        }
    }

    private func startFlow() async {
        await presenter.value.presentSignUp { [weak self] in
            guard let self else { return }
            await handle(event: .canceled)
        }
    }

    private func handle(event: TerminationEvent) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: event)
    }
}

// MARK: - User Actions

extension SignUpFlow {
    @MainActor private func makeActions() -> SignUpViewActions {
        SignUpViewActions(state: viewModel.$state) { [weak self] action in
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
                    await self.signIn()
                }
            }
        }
    }
}

// MARK: - Private

extension SignUpFlow {
    private func signIn() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.value.errorHaptic()
        }
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        await presenter.value.presentLoading()
        do {
            await handle(
                event: .created(
                    try await authUseCase.signup(credentials: credentials)
                )
            )
        } catch {
            await presenter.value.errorHaptic()
            switch error {
            case .alreadyTaken:
                await presenter.value.presentAlreadyTaken()
            case .wrongFormat:
                await presenter.value.presentWrongFormat()
            case .noConnection:
                await presenter.value.presentNoConnection()
            case .other(let error):
                await presenter.value.presentInternalError(error)
            }
        }
    }
}
