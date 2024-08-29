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
        tabBarController.tabBar.tintColor = .p.accent
        tabBarController.tabBar.unselectedItemTintColor = .p.iconSecondary
        tabBarController.tabBar.backgroundColor = .p.backgroundContent
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.modalTransitionStyle = .flipHorizontal
        tabBarController.modalPresentationStyle = .fullScreen
        await router.present(tabBarController)
    }
}
