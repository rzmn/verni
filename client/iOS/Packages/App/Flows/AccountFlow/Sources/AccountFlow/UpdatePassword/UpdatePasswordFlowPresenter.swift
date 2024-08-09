import AppBase

class UpdatePasswordFlowPresenter: Presenter {
    let router: AppRouter
    private weak var flow: UpdatePasswordFlow!

    init(router: AppRouter, flow: UpdatePasswordFlow) {
        self.router = router
        self.flow = flow
    }

    @MainActor func presentHint(message: String) {
        router.hudFailure(description: message)
    }

    private weak var controller: UpdatePasswordViewController?
    @MainActor
    func presentPasswordEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdatePasswordViewController(model: flow)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    @MainActor
    func cancelPasswordEditing() async {
        await router.navigationPop(viewController: controller)
    }
}
