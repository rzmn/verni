import UIKit

public class TextField: UITextField {
    public struct Config {
        public enum ContentType {
            case email
            case password
            case newPassword
            case unspecified
            case unspecifiedSecure
        }
        let content: ContentType
        let placeholder: String
        let formatHint: String?

        public init(placeholder: String, content: ContentType, formatHint: String? = nil) {
            self.content = content
            self.placeholder = placeholder
            self.formatHint = formatHint
        }
    }
    private var config: Config
    private let hintLabel = {
        let l = UILabel()
        l.font = .p.secondaryText
        l.textColor = .p.destructive
        return l
    }()

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        borderStyle = .roundedRect
        render(config)
        [hintLabel].forEach(addSubview)
        clipsToBounds = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let hintSize = hintLabel.sizeThatFits(bounds.size)
        hintLabel.frame = CGRect(
            x: 2,
            y: bounds.maxY,
            width: hintSize.width,
            height: hintSize.height
        )
    }

    public func render(_ config: Config) {
        attributedPlaceholder = NSAttributedString(string: config.placeholder, attributes: [
            .font: UIFont.p.placeholder,
            .foregroundColor: UIColor.secondaryLabel
        ])
        hintLabel.isHidden = config.formatHint == nil
        if hintLabel.text != config.formatHint {
            setNeedsLayout()
        }
        hintLabel.text = config.formatHint
        switch config.content {
        case .email:
            textContentType = .username
            keyboardType = .emailAddress
            autocorrectionType = .no
            isSecureTextEntry = false
            autocapitalizationType = .none
        case .password:
            textContentType = .password
            autocorrectionType = .no
            isSecureTextEntry = true
            autocapitalizationType = .none
        case .newPassword:
            textContentType = .newPassword
            autocorrectionType = .no
            isSecureTextEntry = true
            autocapitalizationType = .none
        case .unspecified:
            textContentType = .none
            autocorrectionType = .no
            isSecureTextEntry = false
            autocapitalizationType = .sentences
        case .unspecifiedSecure:
            textContentType = .none
            autocorrectionType = .no
            isSecureTextEntry = true
            autocapitalizationType = .none
        }
    }
}
