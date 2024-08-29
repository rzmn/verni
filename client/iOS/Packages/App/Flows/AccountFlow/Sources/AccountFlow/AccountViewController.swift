import AppBase
import UIKit
import Combine
internal import Base

class AccountViewController: ViewController<AccountView, AccountViewActions> {
    private lazy var avatarView = {
        let size: CGFloat = 44
        let frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let view = AvatarView(frame: frame)
        view.fitSize = frame.size
        view.layer.masksToBounds = true
        view.layer.cornerRadius = size / 2
        view.contentMode = .scaleAspectFill
        return view
    }()
    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            customView: avatarView
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "qrcode"),
            primaryAction: UIAction(
                handler: curry(model.handle)(.onShowQrTap) • nop
            )
        )
        model.state
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    private func render(state: AccountState) {
        if let value = state.info.value {
            avatarView.avatarId = value.user.avatar?.id
            navigationItem.title = value.user.displayName
        } else {
            avatarView.avatarId = nil
            navigationItem.title = "account_nav_title".localized
        }
    }
}

extension AccountViewController: Routable {
    var name: String {
        "account"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}
