import AppBase

class UpdateDisplayNameFlowPresenter: Presenter {
    let router: AppRouter
    private weak var flow: UpdateDisplayNameFlow!

    init(router: AppRouter, flow: UpdateDisplayNameFlow) {
        self.router = router
        self.flow = flow
    }

    @MainActor
    func presentWrongFormat() {
        router.hudFailure(description: "wrong_format_hint".localized)
    }

    private weak var controller: UpdateDisplayNameViewController?
    @MainActor
    func presentDisplayNameEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdateDisplayNameViewController(model: flow)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    @MainActor
    func dismissDisplayNameEditing() async {
        await router.navigationPop(viewController: controller)
    }
}
