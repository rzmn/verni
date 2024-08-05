import UIKit
import Domain
import DI
import AppBase
internal import SignInFlow
internal import DesignSystem
internal import ProgressHUD

public actor UnauthenticatedFlow {
    private let authUseCase: any AuthUseCaseReturningActiveSession
    private let presenter: UnauthenticatedFlowPresenter

    private let signInFlow: SignInFlow

    private var flowContinuation: CheckedContinuation<ActiveSessionDIContainer, Never>?

    public init(di: DIContainer, router: AppRouter) async {
        authUseCase = di.authUseCase()
        presenter = await UnauthenticatedFlowPresenter(router: router)
        signInFlow = await SignInFlow(di: di, router: router)
    }
}

extension UnauthenticatedFlow: Flow {
    public func perform() async -> ActiveSessionDIContainer {
        await presenter.start(tabs: [signInFlow])
        return await withCheckedContinuation { continuation in
            flowContinuation = continuation
            Task.detached { [weak self] in
                guard let self else { return }
                await flowContinuation?.resume(returning: await signInFlow.perform())
            }
        }
    }
}
