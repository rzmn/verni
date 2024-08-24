import AppBase
import UIKit

class FriendsViewController: ViewController<FriendsView, FriendsFlow> {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "friends_add_button_title".localized,
            image: nil,
            menu: UIMenu(
                children: [
                    UIAction(
                        title: "friends_add_by_qr".localized,
                        image: UIImage(systemName: "qrcode.viewfinder"),
                        handler: { [unowned self] _ in
                            model.addViaQr()
                        }
                    )
                ]
            )
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.refresh()
        model.subscribeForUpdates()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.unsubscribeFromUpdates()
    }
}

extension FriendsViewController: Routable {
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }

    var name: String {
        "friends"
    }
}
