import Foundation
import AppBase

@MainActor class SignUpPresenter: Presenter {
    let router: AppRouter
    private let viewActions: SignUpViewActions

    init(router: AppRouter, actions: SignUpViewActions) {
        self.router = router
        self.viewActions = actions
    }

    weak var signUpController: SignUpViewController?
    func presentSignUp(onPop: @escaping @MainActor () async -> Void) {
        let controller = SignUpViewController(model: viewActions)
        signUpController = controller
        controller.onPop = onPop
        controller.modalPresentationStyle = .fullScreen
        router.push(controller)
    }

    func presentAlreadyTaken() {
        router.hudFailure(description: "email_already_taken".localized)
    }

    func presentWrongFormat() {
        router.hudFailure(description: "wrong_credentials_format_hint".localized)
    }
}
