import UIKit
import Domain
import DI
import AppBase
import Combine
internal import DesignSystem
internal import ProgressHUD

public actor AccountFlow {
    private let router: AppRouter
    private lazy var presenter = AccountFlowPresenter(router: router, flow: self)
    private var flowContinuation: CheckedContinuation<TerminationEvent, Never>?

    public init(di: ActiveSessionDIContainer, router: AppRouter) async {
        self.router = router
    }
}

extension AccountFlow: TabEmbedFlow {
    @MainActor public func viewController() async -> Routable {
        await presenter.tabViewController
    }

    public enum TerminationEvent {
        case logout
    }
    
    public func perform() async -> TerminationEvent {
        await withCheckedContinuation { continuation in
            self.flowContinuation = continuation
        }
    }

    func logout() async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        flowContinuation.resume(returning: .logout)
    }
}
