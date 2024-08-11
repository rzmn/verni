import AppBase
import UIKit

class UserPreviewViewController: ViewController<UserPreviewView, UserPreviewFlow> {}

extension UserPreviewViewController: Routable {
    var name: String {
        "user preview"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
