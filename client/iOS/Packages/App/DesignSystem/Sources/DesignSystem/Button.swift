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

        public init(style: Style, title: String) {
            self.style = style
            self.title = title
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
            backgroundColor = .p.backgroundContent
        case .secondary:
            setTitleColor(.secondaryLabel, for: .normal)
        case .destructive:
            setTitleColor(.p.destructive, for: .normal)
            backgroundColor = .p.destructiveBackground
        }
        setNeedsLayout()
    }
}
