import UIKit
import AppBase

class UpdateDisplayNameViewController: ViewController<UpdateDisplayNameView, UpdateDisplayNameFlow> {
}

extension UpdateDisplayNameViewController: Routable {
    var name: String {
        "update display name"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
