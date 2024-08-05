import AppBase
import UIKit

class AccountFlowPresenter: Presenter {
    let router: AppRouter
    private weak var flow: AccountFlow!

    lazy var tabViewController = {
        let controller = AccountViewController(model: flow)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        controller.navigationItem.title = "account_nav_title".localized
        navigationController.tabBarItem.title = "account_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, flow: AccountFlow) {
        self.router = router
        self.flow = flow
    }
}
