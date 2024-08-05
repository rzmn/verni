import AppBase
import UIKit

class AccountViewController: ViewController<AccountView, AccountFlow> {}

extension AccountViewController: Routable {
    var name: String {
        "account"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
