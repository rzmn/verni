import UIKit
import Domain
import DI
import AppBase
import Combine
internal import SignUpFlow
internal import DesignSystem
internal import ProgressHUD

public actor SignInFlow {
    @MainActor var subject: Published<SignInState>.Publisher {
        viewModel.$state
    }

    private var subscriptions = Set<AnyCancellable>()

    private let viewModel: SignInViewModel

    private let signUpFlow: SignUpFlow
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let saveCredentials: SaveCredendialsUseCase
    private let router: AppRouter

    private lazy var presenter = SignInFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(
        di: DIContainer,
        router: AppRouter
    ) async {
        authUseCase = di.authUseCase()
        viewModel = await SignInViewModel(
            localEmailValidator: di.appCommon().localEmailValidationUseCase(),
            passwordValidator: di.appCommon().localPasswordValidationUseCase()
        )
        saveCredentials = di.appCommon().saveCredentials()
        self.router = router
        self.signUpFlow = await SignUpFlow(di: di, router: router)
    }
}

// MARK: - Flow

extension SignInFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> any Routable {
        await presenter.tabViewController
    }

    public func perform() async -> ActiveSessionDIContainer {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
        }
    }

    private func handle(session: ActiveSessionDIContainer) async {
        guard let flowContinuation else {
            return
        }
        await session.profileRepository().refreshProfile()
        self.flowContinuation = nil
        flowContinuation.resume(returning: session)
    }
}

// MARK: - User Actions

extension SignInFlow {
    @MainActor func update(email: String) {
        viewModel.email = email
    }

    @MainActor func update(password: String) {
        viewModel.password = password
    }

    @MainActor func createAccount() {
        Task.detached {
            await self.doCreateAccount()
        }
    }

    @MainActor func signIn() {
        Task.detached {
            await self.doSignIn()
        }
    }

    @MainActor func openSignIn() {
        Task.detached {
            await self.doOpenSignIn()
        }
    }

    @MainActor func closeSignIn() {
        Task.detached {
            await self.doCloseSignIn()
        }
    }
}

// MARK: - Private

extension SignInFlow {
    private func doCreateAccount() async {
        await presenter.submitHaptic()
        switch await signUpFlow.perform() {
        case .created(let session):
            await handle(session: session)
        case .canceled:
            break
        }
    }

    private func doSignIn() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        await presenter.presentLoading()
        switch await authUseCase.login(credentials: credentials) {
        case .success(let session):
            await saveCredentials.save(email: credentials.email, password: credentials.password)
            await handle(session: session)
        case .failure(let failure):
            await presenter.errorHaptic()
            switch failure {
            case .incorrectCredentials:
                await presenter.presentIncorrectCredentials()
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .noConnection:
                await presenter.presentNoConnection()
            case .other(let error):
                await presenter.presentInternalError(error)
            }
        }
    }

    private func doOpenSignIn() async {
        await presenter.submitHaptic()
        await presenter.presentSignIn()
    }

    private func doCloseSignIn() async {
        subscriptions.removeAll()
        await presenter.dismissSignIn()
    }
}
