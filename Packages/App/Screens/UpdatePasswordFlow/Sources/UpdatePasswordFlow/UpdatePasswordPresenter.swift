import AppBase

@MainActor class UpdatePasswordPresenter: Presenter {
    let router: AppRouter
    private let viewActions: UpdatePasswordViewActions

    init(router: AppRouter, actions: UpdatePasswordViewActions) {
        self.router = router
        self.viewActions = actions
    }

    func presentHint(message: String) {
        router.hudFailure(description: message)
    }

    private weak var controller: UpdatePasswordViewController?
    func presentPasswordEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdatePasswordViewController(model: viewActions)
        self.controller = controller
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }

    func cancelPasswordEditing() async {
        await router.navigationPop(viewController: controller)
    }
}
