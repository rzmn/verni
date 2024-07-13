import UIKit
internal import DesignSystem

class MainViewController: UITabBarController {
    private let model: MainModel

    init(model: MainModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setViewControllers([
            {
                let root = FriendsViewController(
                    model: model.friendsModel
                )
                root.title = "friends_nav_title".localized
                let vc = UINavigationController(
                    rootViewController: root
                )
                vc.navigationBar.prefersLargeTitles = true
                vc.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "person.2.fill")?
                        .withBaselineOffset(fromBottom: 12.0),
                    tag: 1
                )
                return vc
            }(),
            {
                let root = AccountViewController(
                    model: model.accountModel
                )
                let vc = UINavigationController(
                    rootViewController: root
                )
                vc.navigationBar.prefersLargeTitles = true
                vc.navigationBar.tintColor = .p.primary
                vc.tabBarItem = UITabBarItem(
                    title: nil,
                    image: UIImage(systemName: "person.circle.fill")?
                        .withBaselineOffset(fromBottom: 12.0),
                    tag: 2
                )
                return vc
            }()
        ], animated: false)
        tabBar.tintColor = .p.accent
        tabBar.unselectedItemTintColor = .p.iconSecondary
        tabBar.backgroundColor = .p.backgroundContent
        selectedIndex = 1
    }
}
