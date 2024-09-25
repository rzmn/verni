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
        if let host = content.view.closestResponder(of: UIViewController.self) {
            view = UIView()
            addChild(host)
            view.addSubview(content.view)
            content.view.frame = view.bounds
            host.didMove(toParent: self)
        } else {
            view = content.view
        }
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view !== content.view {
            content.view.frame = view.bounds
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController: NavigationStackMember {}
