import AppBase
import UIKit
internal import Base

@MainActor class SignInPresenter: Presenter {
    let router: AppRouter
    private let viewActions: SignInViewActions

    lazy var tabViewController = {
        let controller = SignInHintViewController(model: viewActions)
        let navigationController = NavigationController(
            rootViewController: controller
        )
        controller.navigationItem.title = "account_nav_title".localized
        navigationController.tabBarItem.title = "account_nav_title".localized
        navigationController.tabBarItem.image = UIImage(systemName: "person.crop.circle")
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    init(router: AppRouter, actions: SignInViewActions) {
        self.router = router
        self.viewActions = actions
    }

    weak var signInController: UINavigationController?
    func presentSignIn() async {
        let controller = SignInViewController(model: viewActions)
        let navigationController = NavigationController(rootViewController: controller)
        signInController = navigationController
        navigationController.modalPresentationStyle = .fullScreen
        await router.present(navigationController)
    }

    func dismissSignIn() async {
        guard let signInController else {
            return
        }
        await router.pop(signInController)
    }

    func presentIncorrectCredentials() {
        router.hudFailure(description: "wrong_credentials_hint".localized)
    }

    func presentWrongFormat() {
        router.hudFailure(description: "wrong_credentials_format_hint".localized)
    }
}
