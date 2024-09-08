import UIKit

open class TabBarController<Model, TabBar: UITabBar>: UITabBarController {
    public var onClose: (@MainActor (UIViewController) async -> Void)?
    public var onPop: (@MainActor () async -> Void)?

    public let model: Model
    public var contentTabTar: TabBar {
        loadViewIfNeeded()
        return tabBar as! TabBar
    }

    public init(model: Model) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        let tabBar = TabBar(frame: .zero)
        setValue(tabBar, forKey: "tabBar")
    }

    required public init?(coder: NSCoder) {
        fatalError()
    }
}
