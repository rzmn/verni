import UIKit

@MainActor open class ViewController<V: View<Model>, Model>: UIViewController {
    public var onClose: (@MainActor (UIViewController) async -> Void)?
    public var onPop: (@MainActor () async -> Void)?

    public let model: Model

    var contentView: V {
        // swiftlint:disable:next force_cast
        view as! V
    }

    public init(model: Model) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    open override func loadView() {
        view = V(model: model)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController: NavigationStackMember {}
