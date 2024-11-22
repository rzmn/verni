import UIKit
import SwiftUI

struct TextField: View {
    struct Config {
        let placeholder: LocalizedStringKey
        let hint: LocalizedStringKey
    }
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private(set) var text: String
    @State private var placeholderIsOnFocus: Bool
    private let config: Config
    private var placeholderId: String {
        "placeholderId"
    }
    
    init(text: Binding<String>, config: Config) {
        _text = text
        self.config = config
        self.placeholderIsOnFocus = text.wrappedValue.isEmpty
    }
    
    var body: some View {
        textFieldWithPlaceholderAndHint
            .onChange(of: text) { oldValue, newValue in
                if oldValue.isEmpty != newValue.isEmpty {
                    withAnimation {
                        placeholderIsOnFocus = newValue.isEmpty
                    }
                }
            }
    }
    
    private var textFieldWithPlaceholderAndHint: some View {
        VStack(spacing: 4) {
            textFieldWithPlaceholder
            HStack {
                Text(config.hint)
                    .font(Font.medium(size: 12))
                    .foregroundStyle(colors.text.secondary.default)
                Spacer()
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .frame(height: 74)
    }
    
    @ViewBuilder private var textFieldWithPlaceholder: some View {
        textField
            .overlay {
                VStack {
                    HStack {
                        placeholder(isOnFocus: placeholderIsOnFocus)
                            .id(placeholderId)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    if !placeholderIsOnFocus {
                        Spacer()
                    }
                }
            }
    }
    
    private var textField: some View {
        VStack(spacing: 0) {
            if !placeholderIsOnFocus {
                placeholder(isOnFocus: false)
                    .padding(.bottom, 2)
                    .opacity(0)
            } else {
                Spacer()
            }
            SwiftUI.TextField("", text: $text)
                .font(Font.medium(size: 15))
                .foregroundStyle(colors.text.primary.default)
                .debugBorder(Color.blue)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(colors.background.secondary.default)
        .clipShape(.rect(cornerRadius: paddings.corners.medium))
    }
    
    private func placeholder(isOnFocus: Bool) -> some View {
        Text(config.placeholder)
            .font(Font.medium(size: isOnFocus ? 15 : 12))
            .foregroundStyle(colors.text.secondary.default)
            .padding(.top, isOnFocus ? 0 : 8)
            .debugBorder(.brown)
    }
}

#Preview {
    HStack {
        Spacer()
        VStack {
            Spacer()
            
            TextField(text: .constant(""), config: TextField.Config(placeholder: "Label", hint: "Hint"))
            TextField(text: .constant("Text"), config: TextField.Config(placeholder: "Label", hint: "Hint"))
            
            Spacer()
        }
        Spacer()
    }
    .environment(ColorPalette.dark)
    .environment(PaddingsPalette())
    .loadCustomFonts()
    .ignoresSafeArea()
    .background(Color.white)
}

//public enum TextFieldContentType {
//    case email
//    case displayName
//    case password
//    case oneTimeCode
//    case newPassword
//    case someDescription
//    case numberPad
//}
//
//public enum TextFieldFormatHint: Sendable, Equatable {
//    case acceptable(String)
//    case warning(String)
//    case unacceptable(String)
//
//    var text: String {
//        switch self {
//        case .acceptable(let string):
//            return string
//        case .warning(let string):
//            return string
//        case .unacceptable(let string):
//            return string
//        }
//    }
//}
//
//private let textFieldHeight: CGFloat = 48
//private let hintHeight: CGFloat = 16
//private let cornerRadius: CGFloat = 8
//
//private struct TextFieldStyle: ViewModifier {
//    let content: TextFieldContentType
//    let formatHint: TextFieldFormatHint?
//
//    func body(content: Content) -> some View {
//        VStack(spacing: 0) {
//            content
//                .fontStyle(.text)
//                .autocorrectionDisabled(autocorrectionDisabled)
//                .textContentType(contentType)
//                .textInputAutocapitalization(TextInputAutocapitalization(autocapitalization))
//                .keyboardType(keyboardType)
//                .frame(height: textFieldHeight)
//                .padding(.horizontal, .palette.defaultHorizontal)
//                .background(Color.palette.backgroundContent)
//                .clipShape(.rect(cornerRadius: cornerRadius))
//            if let formatHint {
//                HStack {
//                    VStack(spacing: 0) {
//                        Spacer()
//                        Text(formatHint.text)
//                            .fontStyle(.textSecondary)
//                            .foregroundStyle(color(for: formatHint))
//                        Spacer()
//                    }
//                    Spacer()
//                }
//                .frame(height: hintHeight)
//            } else {
//                Spacer()
//                    .frame(height: hintHeight)
//            }
//        }
//    }
//
//    private func color(for hint: TextFieldFormatHint) -> Color {
//        switch hint {
//        case .acceptable:
//            .palette.positive
//        case .warning:
//            .palette.warning
//        case .unacceptable:
//            .palette.destructive
//        }
//    }
//
//    private var autocorrectionDisabled: Bool {
//        switch content {
//        case .email, .password, .newPassword, .numberPad, .displayName, .oneTimeCode:
//            return true
//        case .someDescription:
//            return false
//        }
//    }
//
//    private var contentType: UITextContentType? {
//        switch content {
//        case .email:
//            return .username
//        case .password:
//            return .password
//        case .newPassword:
//            return .newPassword
//        case .oneTimeCode:
//            return .oneTimeCode
//        case .numberPad, .someDescription, .displayName:
//            return .none
//        }
//    }
//
//    private var autocapitalization: UITextAutocapitalizationType {
//        switch content {
//        case .password, .newPassword, .email, .numberPad, .displayName, .oneTimeCode:
//            return .none
//        case .someDescription:
//            return .sentences
//        }
//    }
//
//    private var keyboardType: UIKeyboardType {
//        switch content {
//        case .email:
//            return .emailAddress
//        case .numberPad:
//            return .decimalPad
//        case .oneTimeCode:
//            return .numberPad
//        case .someDescription, .password, .newPassword, .displayName:
//            return .default
//        }
//    }
//}
//
//extension View {
//    public func textFieldStyle(content: TextFieldContentType, formatHint: TextFieldFormatHint?) -> some View {
//        modifier(TextFieldStyle(content: content, formatHint: formatHint))
//    }
//}
//
//#Preview {
//    VStack(spacing: 12) {
//        TextField(
//            "enter email",
//            text: Binding { "e@mail.com" } set: { _ in }
//        )
//        .textFieldStyle(content: .email, formatHint: .acceptable("email ok"))
//        .debugBorder()
//        TextField(
//            "enter email",
//            text: Binding { "" } set: { _ in }
//        )
//        .textFieldStyle(content: .email, formatHint: nil)
//        .debugBorder()
//        SecureField(
//            "enter password",
//            text: Binding { "password" } set: { _ in }
//        )
//        .textFieldStyle(content: .email, formatHint: .warning("weak password"))
//        .debugBorder()
//        SecureField(
//            "enter password",
//            text: Binding { "))" } set: { _ in }
//        )
//        .textFieldStyle(content: .email, formatHint: .unacceptable("wrong format"))
//        .debugBorder()
//    }
//}
