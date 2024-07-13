import Foundation

actor MainPresenter {
    private weak var model: MainModel?
    private let appRouter: AppRouter

    init(model: MainModel, appRouter: AppRouter) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start() async {
        guard let model = await model else {
            return
        }
        let viewController = MainViewController(model: model)
        viewController.modalTransitionStyle = .flipHorizontal
        await appRouter.present(viewController)
    }
}
