import AppBase
import UIKit

class AddExpenseFlowPresenter: Presenter {
    let router: AppRouter
    private unowned var flow: AddExpenseFlow

    init(router: AppRouter, flow: AddExpenseFlow) {
        self.router = router
        self.flow = flow
    }

    private weak var controller: NavigationController?
    @MainActor func present() async {
        let navigationController = NavigationController(
            rootViewController: AddExpenseViewController(model: flow)
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

    @MainActor func needsPickCounterparty()  {
        router.hudFailure(description: "expense_choose_counterparty".localized)
    }

    @MainActor func privacyViolated() {
        router.hudFailure(description: "expense_add_privacy_violation".localized)
    }
}
