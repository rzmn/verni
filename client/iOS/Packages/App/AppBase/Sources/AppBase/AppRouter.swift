import UIKit
import Logging
import Base
internal import ProgressHUD

@MainActor
public class AppRouter: NSObject {
    public let logger = Logger.shared.with(prefix: "[router] ")

    private let scheduler: AsyncSerialScheduler

    private let window: UIWindow
    private var viewControllers: [UIViewController] = []
    private var dismissHandlers: [UIViewController: [() -> Void]] = [:]

    private var hudWorkItem: DispatchWorkItem?

    public init(window: UIWindow) {
        self.window = window
        self.scheduler = AsyncSerialScheduler()
    }

    public func showHud(graceTime: TimeInterval? = nil) {
        hudWorkItem?.cancel()
        hudWorkItem = nil
        if let graceTime {
            let workItem = DispatchWorkItem { [weak self] in
                self?.doShowHud()
            }
            hudWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(graceTime * 1000)), execute: workItem)
        } else {
            doShowHud()
        }
    }

    public func hudFailure(description: String? = nil) {
        hudWorkItem?.cancel()
        hudWorkItem = nil
        ProgressHUD.error(description, delay: 3)
    }

    func hideHud() {
        hudWorkItem?.cancel()
        hudWorkItem = nil
        ProgressHUD.dismiss()
    }

    private func doShowHud() {
        hudWorkItem = nil
        ProgressHUD.animate()
    }

    public func present(_ controller: Routable, animated: Bool = true) async {
        await scheduler.run { [unowned self] in
            let viewController = controller.create { [unowned self] viewController in
                await pop(viewController)
            }
            await hideHud()
            await doPresent(viewController, animated: animated)
        }
    }

    private func doPresent(_ viewController: UIViewController, animated: Bool) async {
        viewController.presentationController?.delegate = self
        if let navigationController = viewController as? UINavigationController {
            navigationController.delegate = self
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

    public func push(_ controller: Routable) {
        guard let navigation = viewControllers.last as? UINavigationController else {
            return assertionFailure("cannot push from non-navigation controller")
        }
        let viewController = controller.create { [unowned self] viewController in
            await pop(viewController)
        }
        hideHud()
        navigation.pushViewController(viewController, animated: true)
    }

    public func pop(_ viewController: UIViewController) async {
        await scheduler.run {
            await self.doPop(viewController)
        }
    }

    func doPop(_ viewController: UIViewController) async {
        guard viewControllers.last === viewController else {
            return
        }
        await withCheckedContinuation { continuation in
            self.hideHud()
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
