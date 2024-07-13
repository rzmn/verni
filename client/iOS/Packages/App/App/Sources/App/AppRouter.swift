import UIKit
import DesignSystem
import Logging
import Base

@MainActor
public class AppRouter: NSObject {
    public let logger = Logger.shared.with(prefix: "[router] ")

    private let scheduler: AsyncSerialScheduler

    private let window: UIWindow
    private var viewControllers: [UIViewController] = []
    private var dismissHandlers: [UIViewController: [() -> Void]] = [:]

    public init(window: UIWindow) {
        self.window = window
        self.scheduler = AsyncSerialScheduler()
    }

    func alert(config: Alert.Config) async {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        await present(
            AlertController(config: config) { controller in
                await self.pop(controller)
            }
        )
    }

    func present(_ viewController: UIViewController, animated: Bool = true, onDismiss: (() -> Void)? = nil) async {
        await scheduler.run {
            await self.doPresent(viewController, animated: animated, onDismiss: onDismiss)
        }
    }

    private func doPresent(_ viewController: UIViewController, animated: Bool = true, onDismiss: (() -> Void)? = nil) async {
        viewController.presentationController?.delegate = self
        if let navigationController = viewController as? UINavigationController {
            navigationController.delegate = self
        }
        if let onDismiss {
            var handlers = dismissHandlers[viewController] ?? []
            handlers.append(onDismiss)
            dismissHandlers[viewController] = handlers
        }
        if let last = viewControllers.last {
            await withCheckedContinuation { continuation in
                last.present(viewController, animated: animated) { [weak self, weak viewController] in
                    guard let self, let viewController else { return }
                    viewControllers.append(viewController)
                    continuation.resume()
                }
            }
        } else {
            let block = {
                self.window.rootViewController = viewController
                self.viewControllers = [viewController]
                self.window.makeKeyAndVisible()
            }
            if animated {
                block()
            } else {
                UIView.performWithoutAnimation(block)
            }
        }
    }

    func push(_ viewController: UIViewController) {
        guard let navigation = viewControllers.last as? UINavigationController else {
            return assertionFailure("cannot push from non-navigation controller")
        }
        navigation.pushViewController(viewController, animated: true)
    }

    func pop(_ viewController: UIViewController) async {
        await scheduler.run {
            await self.doPop(viewController)
        }
    }

    func doPop(_ viewController: UIViewController) async {
        guard viewControllers.last === viewController else {
            return
        }
        await withCheckedContinuation { continuation in
            viewController.dismiss(animated: true) {
                self.removeLast()
                continuation.resume()
            }
        }
    }
}

extension AppRouter: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if viewControllers.last === presentationController.presentedViewController {
            removeLast()
        }
    }
}

extension AppRouter: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // todo: 
    }
}

extension AppRouter {
    private func removeLast() {
        guard let viewController = viewControllers.popLast() else {
            return
        }
        dismissHandlers[viewController]?.forEach {
            $0()
        }
        dismissHandlers[viewController]?.removeAll()
    }
}

extension AppRouter: Loggable {}
