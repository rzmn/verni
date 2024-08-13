import UIKit

public extension UIControl {
    func addAction(_ block: @escaping () async -> Void, for event: Event) {
        addAction(UIAction(handler: { _ in
            Task.detached { @MainActor in
                await block()
            }
        }), for: event)
    }

    func addAction(_ block: @escaping @MainActor () -> Void, for event: Event) {
        addAction(UIAction(handler: { _ in
            block()
        }), for: event)
    }
}
