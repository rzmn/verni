import UIKit

extension UIResponder {
    public var isInInteractiveTransition: Bool {
        sequence(first: self, next: \.next).contains { responder in
            guard let controller = responder as? UIViewController else {
                return false
            }
            guard let context = controller.transitionCoordinator else {
                return false
            }
            return context.isInteractive
        }
    }
}
