import AppBase
import UIKit
internal import DesignSystem

class AuthenticatedFlowPresenter: Presenter {
    let router: AppRouter
    private unowned var flow: AuthenticatedFlow

    init(router: AppRouter, flow: AuthenticatedFlow) {
        self.router = router
        self.flow = flow
    }

    @MainActor
    func start(tabs: [any TabEmbedFlow]) async {
        let tabBarController = AuthenticatedTabsController(model: flow)

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
