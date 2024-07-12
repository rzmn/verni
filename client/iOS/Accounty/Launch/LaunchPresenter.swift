import UIKit
import Domain
import DesignSystem

@MainActor
class LaunchPresenter {
    private let appRouter: AppRouter

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func start() async {
        guard let controller = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else {
            return
        }
        await appRouter.present(controller, animated: false)
    }

    func display(_ alertConfig: Alert.Config) async {
        await appRouter.alert(config: alertConfig)
    }
}
