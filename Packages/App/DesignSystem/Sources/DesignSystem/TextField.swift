import UIKit
import Combine

fileprivate extension TextField.ContentType {
    var autocorrectionType: UITextAutocorrectionType {
        switch self {
        case .email, .password, .newPassword, .numberPad, .displayName, .oneTimeCode:
            return .no
        case .someDescription:
            return .yes
        }
    }

    var contentType: UITextContentType? {
        switch self {
        case .email:
            return .username
        case .password:
            return .password
        case .newPassword:
            return .newPassword
        case .oneTimeCode:
            return .oneTimeCode
        case .numberPad, .someDescription, .displayName:
            return .none
        }
    }

    var isSecure: Bool {
        switch self {
        case .password, .newPassword:
            return true
        case .email, .numberPad, .someDescription, .displayName, .oneTimeCode:
            return false
        }
    }

    var autocapitalization: UITextAutocapitalizationType {
        switch self {
        case .password, .newPassword, .email, .numberPad, .displayName, .oneTimeCode:
            return .none
        case .someDescription:
            return .sentences
        }
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        case .numberPad:
            return .decimalPad
        case .oneTimeCode:
            return .numberPad
        case .someDescription, .password, .newPassword, .displayName:
            return .default
        }
    }
}

public class TextField: UITextField {
    public enum ContentType {
        case email
        case displayName
        case password
        case oneTimeCode
        case newPassword
        case someDescription
        case numberPad
    }

    public struct Config {
        let content: ContentType
        let placeholder: String
        let formatHint: String?

        public init(placeholder: String, content: ContentType, formatHint: String? = nil) {
            self.content = content
            self.placeholder = placeholder
            self.formatHint = formatHint
        }
    }
    public var textPublisher: AnyPublisher<String?, Never> {
        textSubject.eraseToAnyPublisher()
    }
    private let textSubject = PassthroughSubject<String?, Never>()

    private var config: Config
    private let hintLabel = {
        let label = UILabel()
        label.font = .p.secondaryText
        label.textColor = .p.destructive
        return label
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
        for view in [hintLabel] {
            addSubview(view)
        }
        clipsToBounds = false
        addAction({ [unowned self] in
            textSubject.send(text)
        }, for: .editingChanged)
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

        textContentType = config.content.contentType
        autocorrectionType = config.content.autocorrectionType
        isSecureTextEntry = config.content.isSecure
        autocapitalizationType = config.content.autocapitalization
        keyboardType = config.content.keyboardType
    }
}
