import UIKit

public extension UIControl {
    func addAction(_ block: @escaping @MainActor () -> Void, for event: Event) {
        addAction(UIAction(handler: { _ in
            block()
        }), for: event)
    }
}
