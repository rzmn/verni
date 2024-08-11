import UIKit
import AppBase

class UpdatePasswordViewController: ViewController<UpdatePasswordView, UpdatePasswordFlow> {}

extension UpdatePasswordViewController: Routable {
    var name: String {
        "update password"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
