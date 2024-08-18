import UIKit
import AppBase
internal import Base
internal import DesignSystem

class AuthenticatedTabsController: TabBarController<AuthenticatedFlow, TabBar> {
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTabTar.centerButton.addAction(weak(self, type(of: self).onCenterButtonTap), for: .touchUpInside)
    }

    private func onCenterButtonTap() {
        model.addNewExpense()
    }
}

extension AuthenticatedTabsController: Routable {
    var name: String {
        "authenticated tabs"
    }

    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self
    }
}

class TabBar: UITabBar {
    let centerButton = IconButton(
        config: IconButton.Config(
            icon: UIImage(systemName: "plus.circle")
        )
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(centerButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let buttonSize: CGFloat = bounds.height - safeAreaInsets.bottom
        centerButton.frame = CGRect(
            x: bounds.midX - buttonSize / 2,
            y: 0,
            width: buttonSize,
            height: buttonSize
        )
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden && alpha > 0 else { return nil }

        return centerButton.frame.contains(point) ? centerButton : super.hitTest(point, with: event)
    }
}
