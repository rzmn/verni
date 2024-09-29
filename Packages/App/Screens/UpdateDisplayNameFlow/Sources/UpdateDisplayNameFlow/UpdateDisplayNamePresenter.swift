import AppBase

@MainActor class UpdateDisplayNamePresenter: Presenter {
    let router: AppRouter
    private let viewActions: UpdateDisplayNameViewActions

    init(router: AppRouter, actions: UpdateDisplayNameViewActions) {
        self.router = router
        self.viewActions = actions
    }

    func presentWrongFormat() {
        router.hudFailure(description: "wrong_format_hint".localized)
    }

    private weak var controller: UpdateDisplayNameViewController?
    func presentDisplayNameEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdateDisplayNameViewController(model: viewActions)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    func dismissDisplayNameEditing() async {
        await router.navigationPop(viewController: controller)
    }
}
