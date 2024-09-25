import UIKit

@MainActor open class ViewController<Content: ViewProtocol<Model>, Model>: UIViewController {
    public var onClose: (@MainActor (UIViewController) async -> Void)?
    public var onPop: (@MainActor () async -> Void)?

    public let model: Model
    private var content: Content!

    public var contentView: Content {
        loadViewIfNeeded()
        return content
    }

    public init(model: Model) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    open override func loadView() {
        content = Content(model: model)
        view = content.view
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController: NavigationStackMember {}
