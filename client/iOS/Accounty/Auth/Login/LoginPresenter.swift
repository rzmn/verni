import UIKit
import DesignSystem

actor LoginPresenter {
    private weak var model: LoginModel?
    private let appRouter: AppRouter

    init(model: LoginModel, appRouter: AppRouter) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start() async {
        guard let model = await model else {
            return
        }
        let navigation = UINavigationController(
            rootViewController: LoginViewController(
                model: model
            )
        )
        navigation.modalPresentationStyle = .fullScreen
        navigation.navigationBar.tintColor = .p.accent
        navigation.navigationBar.barTintColor = .p.accent
        await appRouter.present(navigation)
    }

    @MainActor
    func startPasswordEditing() async {
        guard let model = await model else {
            return
        }
        appRouter.push(
            LoginPasswordViewController(
                model: model
            )
        )
    }

    func presentValidationError(hint: String) async {
        await appRouter.alert(
            config: Alert.Config(
                title: "alert_title_error".localized,
                message: hint,
                actions: [
                    Alert.Action(title: "alert_action_ok".localized)
                ]
            )
        )
    }

    func presentConfirmError(hint: String, underlying: Error) async {
        await appRouter.alert(
            config: Alert.Config(
                title: hint,
                message: "\(underlying)",
                actions: [
                    Alert.Action(title: "alert_action_ok".localized)
                ]
            )
        )
    }
}
