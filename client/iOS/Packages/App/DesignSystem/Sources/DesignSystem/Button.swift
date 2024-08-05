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
        setTitle(config.title, for: .normal)
        titleLabel?.font = .p.title2
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
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
