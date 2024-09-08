import AppBase

@MainActor class UpdateEmailPresenter: Presenter {
    let router: AppRouter
    private let viewActions: UpdateEmailViewActions

    init(router: AppRouter, actions: UpdateEmailViewActions) {
        self.router = router
        self.viewActions = actions
    }

    func codeSent() {
        router.hudSuccess(description: "email_code_send_success".localized)
    }

    func codeIsWrong() {
        router.hudFailure(description: "email_code_is_wrong".localized)
    }

    func codeNotDelivered() {
        router.hudFailure(description: "email_code_not_deliveded".localized)
    }

    func emailAlreadyConfirmed() {
        router.hudFailure(description: "email_code_already_confirmed".localized)
    }

    func presentEmailEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdateEmailViewController(model: viewActions)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }
}
