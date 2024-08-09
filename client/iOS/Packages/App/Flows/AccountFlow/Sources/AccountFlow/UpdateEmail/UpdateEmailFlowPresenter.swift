import AppBase

class UpdateEmailFlowPresenter: Presenter {
    let router: AppRouter
    private weak var flow: UpdateEmailFlow!

    init(router: AppRouter, flow: UpdateEmailFlow) {
        self.router = router
        self.flow = flow
    }

    @MainActor
    func presentEmailEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdateEmailViewController(model: flow)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }
}
