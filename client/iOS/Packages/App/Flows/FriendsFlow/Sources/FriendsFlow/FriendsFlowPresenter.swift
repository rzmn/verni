import AppBase
import UIKit

class FriendsFlowPresenter: Presenter {
    let router: AppRouter
    private unowned var flow: FriendsFlow

    lazy var tabViewController = {
        let controller = FriendsViewController(model: flow)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        controller.navigationItem.title = "friends_nav_title".localized
        navigationController.tabBarItem.title = "friends_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.2.fill")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, flow: FriendsFlow) {
        self.router = router
        self.flow = flow
    }
}
