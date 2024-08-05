import UIKit
import Domain
import DI
import AppBase
internal import SignInFlow
internal import DesignSystem
internal import ProgressHUD
internal import AccountFlow

public actor AuthenticatedFlow {
    private let presenter: AuthenticatedFlowPresenter
    private let accountFlow: AccountFlow

    private var flowContinuation: CheckedContinuation<TerminationEvent, Never>?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        presenter = await AuthenticatedFlowPresenter(router: router)
        accountFlow = await AccountFlow(di: di, router: router)
    }
}

extension AuthenticatedFlow: Flow {
    public enum TerminationEvent {
        case logout
    }

    public func perform() async -> TerminationEvent {
        await presenter.start(tabs: [accountFlow])
        return await withCheckedContinuation { continuation in
            flowContinuation = continuation
            Task.detached { [weak self] in
                guard let self else { return }
                let termination = await accountFlow.perform()
                guard let flowContinuation = await self.flowContinuation else {
                    return
                }
                switch termination {
                case .logout:
                    flowContinuation.resume(returning: .logout)
                }
            }
        }
    }
}
