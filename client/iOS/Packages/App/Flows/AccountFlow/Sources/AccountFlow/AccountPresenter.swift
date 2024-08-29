import AppBase
import UIKit

@MainActor class AccountPresenter: Presenter {
    let router: AppRouter
    private let viewAcions: AccountViewActions

    lazy var tabViewController = {
        let controller = AccountViewController(model: viewAcions)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        navigationController.tabBarItem.title = "account_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, actions: AccountViewActions) {
        self.router = router
        self.viewAcions = actions
    }
}
