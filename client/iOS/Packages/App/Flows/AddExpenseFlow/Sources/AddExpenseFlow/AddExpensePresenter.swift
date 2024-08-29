import AppBase
import UIKit

@MainActor class AddExpensePresenter: Presenter {
    let router: AppRouter
    private let viewActions: AddExpenseViewActions

    init(router: AppRouter, actions: AddExpenseViewActions) {
        self.router = router
        self.viewActions = actions
    }

    private weak var controller: NavigationController?
    func present() async {
        let navigationController = NavigationController(
            rootViewController: AddExpenseViewController(model: viewActions)
        )
        self.controller = navigationController
        await router.present(navigationController)
    }

    func dismiss() async {
        guard let controller else {
            return
        }
        self.controller = nil
        await router.pop(controller)
    }

    func needsPickCounterparty()  {
        router.hudFailure(description: "expense_choose_counterparty".localized)
    }

    func privacyViolated() {
        router.hudFailure(description: "expense_add_privacy_violation".localized)
    }
}
