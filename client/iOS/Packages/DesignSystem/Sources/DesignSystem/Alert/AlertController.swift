import UIKit

public class AlertController: UIViewController {
    private class View: UIView {
        private let content: AlertContentView
        private let dismissHandler: () async -> Void

        init(config _config: Alert.Config, dismissHandler: @escaping () async -> Void, automaticallyDismissOnAction: Bool = true) {
            let config: Alert.Config
            if automaticallyDismissOnAction {
                config = Alert.Config(
                    title: _config.title,
                    message: _config.message,
                    actions: _config.actions.map { action in
                        Alert.Action(title: action.title) { controller in
                            await dismissHandler()
                            await action.handler?(controller)
                        }
                    }
                )
            } else {
                config = _config
            }
            self.dismissHandler = dismissHandler
            content = AlertContentView(config: config)
            super.init(frame: .zero)
            setupView()
        }
        
        required init?(coder: NSCoder) {
            fatalError()
        }
        
        private func setupView() {
            backgroundColor = .black.withAlphaComponent(0.26)
            [content].forEach(addSubview)
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapBackground)))
        }

        @objc private func onTapBackground() {
            Task {
                await self.dismissHandler()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let containerSize = content.sizeThatFits(CGSize(width: bounds.width - 32, height: bounds.height))
            content.frame = CGRect(
                x: bounds.midX - containerSize.width / 2,
                y: bounds.midY - containerSize.height / 2,
                width: containerSize.width,
                height: containerSize.height
            )
        }
    }

    private let onDismiss: (UIViewController) async -> Void
    private let config: Alert.Config

    public init(config: Alert.Config, onDismiss: @escaping (UIViewController) async -> Void) {
        self.onDismiss = onDismiss
        self.config = config
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override func loadView() {
        view = {
            let v = View(config: config) { [weak self] in
                guard let self else { return }
                Task {
                    await self.onDismiss(self)
                }
            }
            return v
        }()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}
