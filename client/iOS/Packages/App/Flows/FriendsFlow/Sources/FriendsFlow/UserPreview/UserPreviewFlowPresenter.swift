import AppBase

class UserPreviewFlowPresenter: Presenter {
    let router: AppRouter
    private unowned var flow: UserPreviewFlow

    init(router: AppRouter, flow: UserPreviewFlow) {
        self.router = router
        self.flow = flow
    }

    private weak var controller: UserPreviewViewController?
    @MainActor
    func openUserPreview(onPop: @escaping @MainActor () async -> Void) {
        let controller = UserPreviewViewController(model: flow)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    @MainActor
    func closeUserPreview() async {
        await router.navigationPop(viewController: controller)
    }

    @MainActor
    func present(hint: String) {
        router.hudSuccess(description: hint)
    }
}
