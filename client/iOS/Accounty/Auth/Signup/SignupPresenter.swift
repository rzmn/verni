import UIKit
import DesignSystem

actor SignupPresenter {
    private weak var model: SignupModel?
    private let appRouter: AppRouter

    init(model: SignupModel, appRouter: AppRouter) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start() async {
        guard let model = await model else {
            return
        }
        appRouter.push(SignupViewController(model: model))
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
