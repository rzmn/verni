import UIKit

public class NavigationController: UINavigationController {
    private var onClose: (@MainActor (UIViewController) async -> Void)?
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
