import AppBase
import UIKit

private class CustomView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        layer.cornerRadius = 44 / 2
        backgroundColor = .cyan
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: 44, height: 44)
    }
}

class AccountViewController: ViewController<AccountView, AccountFlow> {
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = CustomView(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            customView: view
        )
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
