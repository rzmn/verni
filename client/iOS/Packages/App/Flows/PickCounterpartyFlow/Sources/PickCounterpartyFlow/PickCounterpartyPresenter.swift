import AppBase
import UIKit

@MainActor class PickCounterpartyPresenter: Presenter {
    let router: AppRouter
    private let actions: PickCounterpartyViewActions

    init(router: AppRouter, actions: PickCounterpartyViewActions) {
        self.router = router
        self.actions = actions
    }

    private weak var controller: NavigationController?
    func present() async {
        let navigationController = NavigationController(
            rootViewController: PickCounterpartyViewController(model: actions)
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
}
