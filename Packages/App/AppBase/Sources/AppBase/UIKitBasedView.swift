import UIKit

open class UIKitBasedView<Model>: UIView, ViewProtocol {
    public let model: Model
    open var view: UIView { self }

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
