import AppBase
import UIKit

@MainActor class FriendsPresenter: Presenter {
    let router: AppRouter
    private let viewActions: FriendsViewActions

    lazy var tabViewController = {
        let controller = FriendsViewController(model: viewActions)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        controller.navigationItem.title = "friends_nav_title".localized
        navigationController.tabBarItem.title = "friends_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.2.fill")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, actions: FriendsViewActions) {
        self.router = router
        self.viewActions = actions
    }
}
