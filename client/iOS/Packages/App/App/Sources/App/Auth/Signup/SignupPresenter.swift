import UIKit
internal import DesignSystem

actor SignupPresenter {
    private weak var model: SignupModel?
    private let appRouter: AppRouter

    init(model: SignupModel, appRouter: AppRouter) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start(onDismiss: @escaping () async -> Void) async {
        guard let model = await model else {
            return
        }
        let navigationController = UINavigationController(
            rootViewController: SignupViewController(model: model)
        )
        navigationController.navigationBar.tintColor = .p.accent
        navigationController.navigationBar.barTintColor = .p.accent
        await appRouter.present(navigationController) {
            Task {
                await onDismiss()
            }
        }
    }

    @MainActor
    func startPasswordEditing() async {
        guard let model = await model else {
            return
        }
        appRouter.push(SignupPasswordViewController(model: model))
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
