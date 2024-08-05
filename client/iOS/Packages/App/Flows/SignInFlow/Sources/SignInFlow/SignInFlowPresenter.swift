import AppBase
import UIKit
internal import Base

class SignInFlowPresenter: Presenter {
    private weak var flow: SignInFlow!
    let router: AppRouter

    lazy var tabViewController = {
        let controller = SignInHintViewController(model: flow)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        controller.navigationItem.title = "account_nav_title".localized
        navigationController.tabBarItem.title = "account_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, flow: SignInFlow) {
        self.flow = flow
        self.router = router
    }

    weak var signInController: UINavigationController?
    @MainActor
    func presentSignIn() async {
        let controller = SignInViewController(model: flow)
        let navigationController = NavigationController(rootViewController: controller)
        signInController = navigationController
        navigationController.modalPresentationStyle = .fullScreen
        await router.present(navigationController)
    }

    @MainActor
    func dismissSignIn() async {
        guard let signInController else {
            return
        }
        await router.pop(signInController)
    }

    @MainActor
    func presentIncorrectCredentials() {
        router.hudFailure(description: "wrong_credentials_hint".localized)
    }

    @MainActor
    func presentWrongFormat() {
        router.hudFailure(description: "wrong_credentials_format_hint".localized)
    }
}
