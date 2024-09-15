import UIKit

@MainActor public protocol Routable {
    var name: String { get }
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController
}

@MainActor public protocol NavigationStackMember {
    var onPop: (@MainActor () async -> Void)? { get }
}
