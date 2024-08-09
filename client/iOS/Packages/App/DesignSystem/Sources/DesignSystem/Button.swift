import UIKit

public class Button: UIButton {
    public struct Config {
        public enum Style {
            case primary
            case secondary
            case destructive
        }
        public let style: Style
        public let title: String
        public let enabled: Bool

        public init(style: Style, title: String, enabled: Bool = true) {
            self.style = style
            self.title = title
            self.enabled = enabled
        }
    }

    public init(config: Config) {
        super.init(frame: .zero)
        titleLabel?.font = .p.title2
        titleLabel?.numberOfLines = 0
        layer.masksToBounds = true
        layer.cornerRadius = 10
        render(config: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    public func render(config: Config) {
        setTitle(config.title, for: .normal)
        switch config.style {
        case .primary:
            setTitleColor(.p.primary, for: .normal)
            setTitleColor(.p.primary.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .p.backgroundContent
        case .secondary:
            setTitleColor(.secondaryLabel, for: .normal)
            setTitleColor(.secondaryLabel.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .clear
        case .destructive:
            setTitleColor(.p.destructive, for: .normal)
            setTitleColor(.p.destructive.withAlphaComponent(0.34), for: .highlighted)
            backgroundColor = .p.destructiveBackground
        }
        alpha = config.enabled ? 1 : 0.64
        setNeedsLayout()
    }
}
