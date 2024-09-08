import AppBase
import UIKit
internal import Base

class FriendsViewController: ViewController<FriendsView, FriendsViewActions> {
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
                        handler: curry(model.handle)(.onAddViaQrTap) • nop
                    )
                ]
            )
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.handle(.onViewAppeared)
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
