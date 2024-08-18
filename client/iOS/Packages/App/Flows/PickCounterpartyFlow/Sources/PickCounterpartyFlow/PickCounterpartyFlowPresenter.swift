import AppBase
import UIKit

class PickCounterpartyFlowPresenter: Presenter {
    let router: AppRouter
    private unowned var flow: PickCounterpartyFlow

    init(router: AppRouter, flow: PickCounterpartyFlow) {
        self.router = router
        self.flow = flow
    }

    private weak var controller: NavigationController?
    @MainActor func present() async {
        let navigationController = NavigationController(
            rootViewController: PickCounterpartyViewController(model: flow)
        )
        self.controller = navigationController
        await router.present(navigationController)
    }

    @MainActor func dismiss() async {
        guard let controller else {
            return
        }
        self.controller = nil
        await router.pop(controller)
    }
}
