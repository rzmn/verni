import Foundation
import AppBase

class SignUpFlowPresenter: Presenter {
    private weak var flow: SignUpFlow!
    let router: AppRouter

    init(router: AppRouter, flow: SignUpFlow) {
        self.flow = flow
        self.router = router
    }

    weak var signUpController: SignUpViewController?
    @MainActor
    func presentSignUp() async {
        let controller = SignUpViewController(model: flow)
        signUpController = controller
        controller.modalPresentationStyle = .fullScreen
        router.push(controller)
    }

    @MainActor
    func presentAlreadyTaken() {
        router.hudFailure(description: "email_already_taken".localized)
    }

    @MainActor
    func presentWrongFormat() {
        router.hudFailure(description: "wrong_credentials_format_hint".localized)
    }
}
