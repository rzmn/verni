import UIKit
internal import Base

public class NavigationController: UINavigationController {
    private var onClose: (@MainActor (UIViewController) async -> Void)?
    private lazy var delegateAdapter = DelegateAdapter(holderController: self)
    public override var delegate: (any UINavigationControllerDelegate)? {
        get {
            delegateAdapter.externalDelegate
        }
        set {
            delegateAdapter.externalDelegate = newValue
        }
    }

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        super.delegate = delegateAdapter
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NavigationController: Routable {
    public var name: String {
        guard let name = (topViewController as? Routable)?.name else {
            assertionFailure("empty navigation controller is being asked for name")
            return "navigation controller"
        }
        return name
    }
    
    public func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
}

extension NavigationController {
    private class DelegateAdapter: NSObject, UINavigationControllerDelegate {
        weak var externalDelegate: UINavigationControllerDelegate?
        weak var holderController: NavigationController?
        private let scheduler = AsyncSerialScheduler()

        private var latestVisibleStack: [UIViewController]

        init(holderController: NavigationController) {
            self.holderController = holderController
            latestVisibleStack = holderController.viewControllers
        }

        public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
            externalDelegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
        }

        public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            externalDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
            guard let holderController, holderController === navigationController else {
                return
            }
            guard holderController.viewControllers.count < latestVisibleStack.count else {
                latestVisibleStack = holderController.viewControllers
                return
            }
            let latestVisibleStack = latestVisibleStack
            Task.detached { @MainActor in
                for viewController in latestVisibleStack[holderController.viewControllers.count ..< latestVisibleStack.count].reversed() {
                    guard let navigationStackMember = viewController as? NavigationStackMember else {
                        continue
                    }
                    await navigationStackMember.onPop?()
                }
            }
            self.latestVisibleStack = holderController.viewControllers
        }
    }
}
