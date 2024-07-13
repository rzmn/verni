import Foundation

class UserPresenter {
    private weak var model: UserModel?
    private let appRouter: AppRouter

    init(appRouter: AppRouter, model: UserModel) {
        self.model = model
        self.appRouter = appRouter
    }

    @MainActor
    func start(onDismiss: @escaping () async -> Void) async {
        guard let model else {
            return
        }
        let viewController = UserViewController(model: model)
        await appRouter.present(viewController) {
            Task {
                await onDismiss()
            }
        }
    }
}
