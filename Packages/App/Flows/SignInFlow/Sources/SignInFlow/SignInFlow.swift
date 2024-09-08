import UIKit
import Domain
import DI
import AppBase
import Combine
internal import SignUpFlow
internal import DesignSystem
internal import ProgressHUD

public actor SignInFlow {
    private var _presenter: SignInPresenter?
    private func presenter() async -> SignInPresenter {
        guard let _presenter else {
            let presenter = await SignInPresenter(router: router, actions: await makeActions())
            _presenter = presenter
            return presenter
        }
        return _presenter
    }
    private var subscriptions = Set<AnyCancellable>()
    private let viewModel: SignInViewModel
    private let signUpFlow: SignUpFlow
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let saveCredentials: SaveCredendialsUseCase
    private let router: AppRouter
    private var flowContinuation: Continuation?

    public init(di: DIContainer, router: AppRouter) async {
        authUseCase = await di.authUseCase()
        viewModel = await SignInViewModel(
            localEmailValidator: di.appCommon.localEmailValidationUseCase,
            passwordValidator: di.appCommon.localPasswordValidationUseCase
        )
        saveCredentials = di.appCommon.saveCredentialsUseCase
        self.router = router
        self.signUpFlow = await SignUpFlow(di: di, router: router)
    }
}

// MARK: - Flow

extension SignInFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> any Routable {
        await presenter().tabViewController
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
        _ = try? await session.profileRepository.refreshProfile()
        self.flowContinuation = nil
        flowContinuation.resume(returning: session)
    }
}

// MARK: - User Actions

extension SignInFlow {
    private func makeActions() async -> SignInViewActions {
        await SignInViewActions(state: viewModel.$state) { [weak self] action in
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
            case .onCreateAccountTap:
                Task {
                    await self.createAccount()
                }
            case .onSignInTap:
                Task {
                    await self.signIn()
                }
            case .onSignInCloseTap:
                Task {
                    await self.closeSignIn()
                }
            }
        }
    }
}

// MARK: - Private

extension SignInFlow {
    private func createAccount() async {
        await presenter().submitHaptic()
        switch await signUpFlow.perform() {
        case .created(let session):
            await handle(session: session)
        case .canceled:
            break
        }
    }

    private func signIn() async {
        let state = await viewModel.state
        guard state.canConfirm else {
            return await presenter().errorHaptic()
        }
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        await presenter().presentLoading()
        do {
            let session = try await authUseCase.login(credentials: credentials)
            await saveCredentials.save(email: credentials.email, password: credentials.password)
            await handle(session: session)
        } catch {
            await presenter().errorHaptic()
            switch error {
            case .incorrectCredentials:
                await presenter().presentIncorrectCredentials()
            case .wrongFormat:
                await presenter().presentWrongFormat()
            case .noConnection:
                await presenter().presentNoConnection()
            case .other(let error):
                await presenter().presentInternalError(error)
            }
        }
    }

    private func openSignIn() async {
        await presenter().submitHaptic()
        await presenter().presentSignIn()
    }

    private func closeSignIn() async {
        subscriptions.removeAll()
        await presenter().dismissSignIn()
    }
}
