import UIKit
import Combine
import SwiftUI

extension DS {
    public struct TextField: View {
        public enum ContentType {
            case email
            case displayName
            case password
            case oneTimeCode
            case newPassword
            case someDescription
            case numberPad
        }
        let content: ContentType
        let text: Binding<String>
        let placeholder: String
        let formatHint: String?

        public init(content: ContentType, text: Binding<String>, placeholder: String, formatHint: String?) {
            self.content = content
            self.text = text
            self.placeholder = placeholder
            self.formatHint = formatHint
        }

        public var body: some View {
            textField
                .autocorrectionDisabled(autocorrectionDisabled)
                .textContentType(contentType)
                .textInputAutocapitalization(TextInputAutocapitalization(autocapitalization))
                .keyboardType(keyboardType)
                .frame(height: .palette.buttonHeight)
        }

        @ViewBuilder private var textField: some View {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                SwiftUI.TextField(placeholder, text: text)
            }
        }

        private var autocorrectionDisabled: Bool {
            switch content {
            case .email, .password, .newPassword, .numberPad, .displayName, .oneTimeCode:
                return true
            case .someDescription:
                return false
            }
        }

        private var contentType: UITextContentType? {
            switch content {
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

        private var isSecure: Bool {
            switch content {
            case .password, .newPassword:
                return true
            case .email, .numberPad, .someDescription, .displayName, .oneTimeCode:
                return false
            }
        }

        private var autocapitalization: UITextAutocapitalizationType {
            switch content {
            case .password, .newPassword, .email, .numberPad, .displayName, .oneTimeCode:
                return .none
            case .someDescription:
                return .sentences
            }
        }

        private var keyboardType: UIKeyboardType {
            switch content {
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
}

#Preview {
    VStack {
        DS.TextField(
            content: .email,
            text: Binding(get: { "e@mail.com" }, set: { _ in }),
            placeholder: "enter email",
            formatHint: nil
        ).debugBorder()
        DS.TextField(
            content: .email,
            text: Binding(get: { "" }, set: { _ in }),
            placeholder: "enter email",
            formatHint: nil
        )
        DS.TextField(
            content: .password,
            text: Binding(get: { "password" }, set: { _ in }),
            placeholder: "enter password",
            formatHint: nil
        )
        DS.TextField(
            content: .password,
            text: Binding(get: { "" }, set: { _ in }),
            placeholder: "enter password",
            formatHint: nil
        )
    }
}

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
        label.font = .palette.secondaryText
        label.textColor = .palette.destructive
        return label
    }()

    public init(config: Config) {
        self.config = config
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            .font: UIFont.palette.placeholder,
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
