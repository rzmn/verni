import UIKit
import AppBase

class AuthenticatedTabsController: UITabBarController {}

extension AuthenticatedTabsController: Routable {
    var name: String {
        "authenticated tabs"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self
    }
}
