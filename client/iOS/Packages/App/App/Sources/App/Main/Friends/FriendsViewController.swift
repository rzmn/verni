import UIKit

class FriendsViewController: UIViewController {
    private let model: FriendsModel

    init(model: FriendsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = FriendsView(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "qrcode.viewfinder"),
                style: .plain,
                target: self,
                action: #selector(onAddFriendViaQr)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "plus.magnifyingglass"),
                style: .plain,
                target: self,
                action: #selector(onAddFriendViaSearch)
            ),
        ]
        navigationItem.rightBarButtonItems?.forEach {
            $0.tintColor = .p.accent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task.detached {
            await self.model.refresh()
        }
    }

    @objc private func onAddFriendViaQr() {
        Task {
            await self.model.addFriendViaQr()
        }
    }

    @objc private func onAddFriendViaSearch() {
        Task {
            await self.model.searchForFriends()
        }
    }
}
