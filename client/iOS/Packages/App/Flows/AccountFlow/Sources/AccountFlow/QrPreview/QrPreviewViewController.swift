import UIKit
import Domain
import AppBase

class QrPreviewViewController: ViewController<QrPreviewView, QrPreviewFlow> {}

extension QrPreviewViewController: Routable {
    var name: String {
        "qr preview"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
