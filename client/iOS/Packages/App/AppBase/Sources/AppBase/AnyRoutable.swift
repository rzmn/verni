import UIKit

public class AnyRoutable: NSObject {
    public let controller: UIViewController

    var onClose: (@MainActor (UIViewController) async -> Void)?
    private let _name: String

    public init(controller: UIViewController, name: String) {
        self.controller = controller
        _name = name
    }
}

extension AnyRoutable: Routable {
    public var name: String {
        _name
    }

    public func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return controller
    }
}
