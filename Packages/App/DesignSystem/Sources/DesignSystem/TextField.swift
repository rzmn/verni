import UIKit
import Combine
import SwiftUI

public enum TextFieldContentType {
    case email
    case displayName
    case password
    case oneTimeCode
    case newPassword
    case someDescription
    case numberPad
}

private struct TextFieldStyle: ViewModifier {
    let content: TextFieldContentType
    let formatHint: String?

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .autocorrectionDisabled(autocorrectionDisabled)
                .textContentType(contentType)
                .textInputAutocapitalization(TextInputAutocapitalization(autocapitalization))
                .keyboardType(keyboardType)
                .frame(height: .palette.buttonHeight)
            if let formatHint {
                HStack {
                    VStack {
                        Text(formatHint)
                            .font(.palette.subtitle)
                        Spacer()
                    }
                    .frame(height: 18)
                    Spacer()
                }
            } else {
                Spacer()
                    .frame(height: 18)
            }
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

extension View {
    public func textFieldStyle(content: TextFieldContentType, formatHint: String?) -> some View {
        modifier(TextFieldStyle(content: content, formatHint: formatHint))
    }
}

#Preview {
    VStack(spacing: 12) {
        TextField(
            "enter email",
            text: Binding(get: { "e@mail.com" }, set: { _ in })
        )
        .textFieldStyle(content: .email, formatHint: nil)
        .debugBorder()
        TextField(
            "enter email",
            text: Binding(get: { "" }, set: { _ in })
        )
        .textFieldStyle(content: .email, formatHint: "email is empty")
        .debugBorder()
        SecureField(
            "enter password",
            text: Binding(get: { "password" }, set: { _ in })
        )
        .textFieldStyle(content: .email, formatHint: nil)
        .debugBorder()
        SecureField(
            "enter password",
            text: Binding(get: { "" }, set: { _ in })
        )
        .textFieldStyle(content: .email, formatHint: "password is empty")
        .debugBorder()
    }
}
