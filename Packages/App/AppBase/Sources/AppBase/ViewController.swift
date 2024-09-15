import UIKit

@MainActor open class ViewController<V: View<Model>, Model>: UIViewController {
    public var onClose: (@MainActor (UIViewController) async -> Void)?
    public var onPop: (@MainActor () async -> Void)?

    public let model: Model

    var contentView: V {
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
        fatalError()
    }
}

extension ViewController: NavigationStackMember {}
