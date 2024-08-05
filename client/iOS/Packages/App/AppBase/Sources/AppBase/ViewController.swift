import UIKit

open class View<Model>: UIView {
    public let model: Model

    public required init(model: Model) {
        self.model = model
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError()
    }
    
    open func setupView() {}
}

open class ViewController<V: View<Model>, Model>: UIViewController {
    public var onClose: (@MainActor (UIViewController) async -> Void)?
    let model: Model

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
