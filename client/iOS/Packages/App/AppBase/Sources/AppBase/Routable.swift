import UIKit

public protocol Routable {
    var name: String { get }
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController
}
