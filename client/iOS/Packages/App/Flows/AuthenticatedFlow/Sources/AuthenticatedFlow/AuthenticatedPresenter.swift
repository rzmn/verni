import AppBase
import UIKit
internal import DesignSystem

@MainActor class AuthenticatedPresenter: Presenter {
    let router: AppRouter
    private let viewActions: AuthenticatedViewActions

    init(router: AppRouter, actions: AuthenticatedViewActions) {
        self.router = router
        self.viewActions = actions
    }

    func start(tabs: [any TabEmbedFlow]) async {
        let tabBarController = AuthenticatedTabsController(model: viewActions)

        var viewControllers = [UIViewController]()
        for flow in tabs {
            viewControllers.append(await flow.viewController().create(onClose: { _ in}))
        }
        tabBarController.setViewControllers(viewControllers, animated: false)
        tabBarController.modalTransitionStyle = .flipHorizontal
        tabBarController.modalPresentationStyle = .fullScreen
        await router.present(tabBarController)
    }
}
