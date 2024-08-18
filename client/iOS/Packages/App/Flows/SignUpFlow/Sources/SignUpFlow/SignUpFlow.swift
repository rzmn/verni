import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor SignUpFlow {
    @MainActor var subject: Published<SignUpState>.Publisher {
        viewModel.$state
    }
    private let viewModel: SignUpViewModel

    private var subscriptions = Set<AnyCancellable>()

    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let router: AppRouter
    private lazy var presenter = SignUpFlowPresenter(router: router, flow: self)
    private var flowContinuation: Continuation?

    public init(di: DIContainer, router: AppRouter) async {
        self.router = router
        authUseCase = di.authUseCase()
        viewModel = await SignUpViewModel(
            localEmailValidator: di.appCommon().localEmailValidationUseCase(),
            localPasswordValidator: di.appCommon().localPasswordValidationUseCase()
        )
    }
}

extension SignUpFlow: Flow {
    public func perform() async -> ActiveSessionDIContainer? {
        await presenter.presentSignUp()
        return await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
        }
    }

    func signIn() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter.errorHaptic()
        }
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        await presenter.presentLoading()
        switch await authUseCase.signup(credentials: credentials) {
        case .success(let session):
            guard let flowContinuation else {
                break
            }
            self.flowContinuation = nil
            flowContinuation.resume(returning: session)
        case .failure(let failure):
            await presenter.errorHaptic()
            switch failure {
            case .alreadyTaken:
                await presenter.presentAlreadyTaken()
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .noConnection:
                await presenter.presentNoConnection()
            case .other(let error):
                await presenter.presentInternalError(error)
            }
        }
    }

    @MainActor func update(email: String) {
        viewModel.email = email
    }

    @MainActor func update(password: String) {
        viewModel.password = password
    }

    @MainActor func update(passwordRepeat: String) {
        viewModel.passwordRepeat = passwordRepeat
    }
}
