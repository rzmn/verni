import AppBase
import UIKit

class SignInHintViewController: ViewController<SignInHintView, SignInFlow> {}

extension SignInHintViewController: Routable {
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }

    var name: String {
        "sign in"
    }
}

