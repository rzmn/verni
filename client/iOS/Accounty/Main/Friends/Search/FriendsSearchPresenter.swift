import UIKit

class FriendsSearchPresenter {
    private weak var model: FriendsSearchModel?
    private let appRouter: AppRouter

    init(model: FriendsSearchModel, appRouter: AppRouter) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start() async {
        guard let model else {
            return
        }
        let navigationController = UINavigationController(
            rootViewController: FriendsSearchViewController(
                model: model
            )
        )
        navigationController.navigationBar.barTintColor = .p.background
        navigationController.navigationBar.backgroundColor = .p.background
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.titleTextAttributes = [
            .font: UIFont.p.title2
        ]
        await appRouter.present(navigationController)
    }
}
