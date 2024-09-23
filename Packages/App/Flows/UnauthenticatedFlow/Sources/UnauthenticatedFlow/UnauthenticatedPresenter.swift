import UIKit
import AppBase
internal import SignInFlow
internal import DesignSystem

@MainActor class UnauthenticatedPresenter {
    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    func start(tabs: [any TabEmbedFlow]) async {
        let tabBarController = UnauthenticatedTabsController(nibName: nil, bundle: nil)

        var viewControllers = [UIViewController]()
        for flow in tabs {
            viewControllers.append(await flow.viewController().create(onClose: { _ in}))
        }
        tabBarController.tabBar.tintColor = .palette.accent
        tabBarController.tabBar.unselectedItemTintColor = .palette.iconSecondary
        tabBarController.tabBar.backgroundColor = .palette.backgroundContent
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.modalTransitionStyle = .flipHorizontal
        tabBarController.modalPresentationStyle = .fullScreen
        await router.present(tabBarController)
    }
}
