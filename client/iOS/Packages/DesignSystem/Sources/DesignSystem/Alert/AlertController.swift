import UIKit

public class AlertController: UIViewController {
    private class View: UIView {
        private let content: AlertContentView
        private let onBackgroundTapHandler: () -> Void

        init(config: Alert.Config, onBackgroundTapHandler: @escaping () -> Void) {
            self.onBackgroundTapHandler = onBackgroundTapHandler
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
            onBackgroundTapHandler()
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

    private let onDismiss: () -> Void
    private let config: Alert.Config

    public init(config: Alert.Config, onDismiss: @escaping () -> Void) {
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
                self?.dismiss(animated: true)
                self?.onDismiss()
            }
            return v
        }()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}
