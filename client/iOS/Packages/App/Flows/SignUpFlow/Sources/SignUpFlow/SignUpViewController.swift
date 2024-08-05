import UIKit
import AppBase

class SignUpViewController: ViewController<SignUpView, SignUpFlow> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "signup_title".localized
        navigationItem.largeTitleDisplayMode = .always
    }
}

extension SignUpViewController: Routable {
    var name: String {
        "sign up"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
