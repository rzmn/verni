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

    private var flowContinuation: Continuation?

    public init(di: DIContainer, router: AppRouter) async {
        authUseCase = di.authUseCase()
        presenter = await UnauthenticatedFlowPresenter(router: router)
        signInFlow = await SignInFlow(di: di, router: router)
    }
}

extension UnauthenticatedFlow: Flow {
    public func perform(willFinish: ((ActiveSessionDIContainer) async -> Void)?) async -> ActiveSessionDIContainer {
        await presenter.start(tabs: [signInFlow])
        return await withCheckedContinuation { continuation in
            flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { [weak self] in
                guard let self else { return }
                await handle(result: await signInFlow.perform())
            }
        }
    }

    private func handle(result: ActiveSessionDIContainer) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        await flowContinuation.willFinishHandler?(result)
        flowContinuation.continuation.resume(returning: result)
    }
}
