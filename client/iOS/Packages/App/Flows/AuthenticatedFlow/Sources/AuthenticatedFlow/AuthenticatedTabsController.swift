import UIKit
import AppBase
import Combine
internal import Base
internal import DesignSystem

class AuthenticatedTabsController: TabBarController<AuthenticatedFlow, TabBar> {
    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .p.accent
        tabBar.unselectedItemTintColor = .p.iconSecondary
        tabBar.backgroundColor = .p.backgroundContent
        model.subject
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        contentTabTar.centerButton.addAction(weak(self, type(of: self).onCenterButtonTap), for: .touchUpInside)
    }

    private func render(state: AuthenticatedState) {
        if let selectedIndex = state.tabs.firstIndex(of: state.activeTab), self.selectedIndex != selectedIndex {
            self.selectedIndex = selectedIndex
        }
    }

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else {
            return
        }
        model.selected(index: index)
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
