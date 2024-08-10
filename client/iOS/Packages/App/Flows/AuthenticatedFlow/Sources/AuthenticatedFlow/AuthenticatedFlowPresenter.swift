import AppBase
import UIKit

class AuthenticatedFlowPresenter: Presenter {
    let router: AppRouter

    @MainActor
    init(router: AppRouter) {
        self.router = router
    }

    @MainActor
    func start(tabs: [any TabEmbedFlow]) async {
        let tabBarController = AuthenticatedTabsController(nibName: nil, bundle: nil)

        var viewControllers = [UIViewController]()
        for flow in tabs {
            viewControllers.append(await flow.viewController().create(onClose: { _ in}))
        }
        tabBarController.tabBar.tintColor = .p.accent
        tabBarController.tabBar.unselectedItemTintColor = .p.iconSecondary
        tabBarController.tabBar.backgroundColor = .p.backgroundContent
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.modalTransitionStyle = .flipHorizontal
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.selectedIndex = tabs.count - 1
        await router.present(tabBarController)
    }
}
