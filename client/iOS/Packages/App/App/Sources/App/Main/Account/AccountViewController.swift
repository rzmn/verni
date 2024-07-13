import UIKit
import Combine
internal import DesignSystem

class AccountViewController: UIViewController {
    private let model: AccountModel
    private var subscriptions = Set<AnyCancellable>()

    init(model: AccountModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = AccountView(model: model)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "account_nav_title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "qrcode"),
            style: .plain,
            target: self,
            action: #selector(onQr)
        )
        navigationItem.rightBarButtonItem?.tintColor = .p.accent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task.detached {
            await self.model.refresh()
        }
    }

    @objc private func onQr() {
        Task.detached {
            await self.model.showQr()
        }
    }
}
