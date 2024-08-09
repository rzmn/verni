import UIKit

public protocol Routable {
    var name: String { get }
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController
}

public protocol NavigationStackMember {
    var onPop: (@MainActor () async -> Void)? { get }
}
