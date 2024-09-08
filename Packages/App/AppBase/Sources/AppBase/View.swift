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
