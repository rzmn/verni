import AppBase

class UpdateEmailFlowPresenter: Presenter {
    let router: AppRouter
    private weak var flow: UpdateEmailFlow!

    init(router: AppRouter, flow: UpdateEmailFlow) {
        self.router = router
        self.flow = flow
    }

    @MainActor
    func codeSent() {
        router.hudSuccess(description: "email_code_send_success".localized)
    }

    @MainActor
    func codeIsWrong() {
        router.hudFailure(description: "email_code_is_wrong".localized)
    }

    @MainActor
    func codeNotDelivered() {
        router.hudFailure(description: "email_code_not_deliveded".localized)
    }

    @MainActor
    func emailAlreadyConfirmed() {
        router.hudFailure(description: "email_code_already_confirmed".localized)
    }

    @MainActor
    func presentEmailEditing(onPop: @escaping @MainActor () async -> Void) {
        let controller = UpdateEmailViewController(model: flow)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.onPop = onPop
        router.push(controller)
    }
}
