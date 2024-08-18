import AppBase
import UIKit
import Combine

class AccountViewController: ViewController<AccountView, AccountFlow> {
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
                handler: { _ in
                    Task.detached { [weak self] in
                        await self?.model.showQr()
                    }
                }
            )
        )
        model.subject
            .sink(receiveValue: render)
            .store(in: &subscriptions)
    }

    private func render(state: AccountState) {
        switch state.info {
        case .initial:
            avatarView.avatarId = nil
        case .loading(let previous):
            if case .loaded(let t) = previous {
                avatarView.avatarId = t.user.avatar?.id
            } else {
                avatarView.avatarId = nil
            }
        case .loaded(let t):
            avatarView.avatarId = t.user.avatar?.id
        case .failed(let previous, _):
            if case .loaded(let t) = previous {
                avatarView.avatarId = t.user.avatar?.id
            } else {
                avatarView.avatarId = nil
            }
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
