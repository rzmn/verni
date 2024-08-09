import UIKit
import AppBase

class UpdateEmailViewController: ViewController<UpdateEmailView, UpdateEmailFlow> {

}

extension UpdateEmailViewController: Routable {
    var name: String {
        "update email"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
