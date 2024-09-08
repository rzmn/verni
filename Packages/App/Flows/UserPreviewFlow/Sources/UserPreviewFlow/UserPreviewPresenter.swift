import AppBase

@MainActor class UserPreviewPresenter: Presenter {
    let router: AppRouter
    private let viewActions: UserPreviewViewActions

    init(router: AppRouter, actions: UserPreviewViewActions) {
        self.router = router
        self.viewActions = actions
    }

    private weak var controller: UserPreviewViewController?
    func openUserPreview(onPop: @escaping @MainActor () async -> Void) {
        let controller = UserPreviewViewController(model: viewActions)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    func closeUserPreview() async {
        await router.navigationPop(viewController: controller)
    }

    func present(hint: String) {
        router.hudSuccess(description: hint)
    }
}
