import UIKit
import AppBase

class UnauthenticatedTabsController: UITabBarController {}

extension UnauthenticatedTabsController: Routable {
    var name: String {
        "unauthenticated tabs"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self
    }
}
