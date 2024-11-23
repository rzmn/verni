import UIKit
import SwiftUI

public struct TextField: View {
    public enum Content {
        case email
        case displayName
        case password
        case newPassword
        case oneTimeCode
        case numberPad
        case unspecified
    }
    public struct Config {
        let placeholder: LocalizedStringKey
        let hint: LocalizedStringKey?
        let content: Content
        
        public init(placeholder: LocalizedStringKey, hint: LocalizedStringKey? = nil, content: Content = .unspecified) {
            self.placeholder = placeholder
            self.hint = hint
            self.content = content
        }
    }
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors
    @Binding private(set) var text: String
    @State private var placeholderIsOnFocus: Bool
    private let config: Config
    private var placeholderId: String {
        "placeholderId"
    }
    
    public init(text: Binding<String>, config: Config) {
        _text = text
        self.config = config
        self.placeholderIsOnFocus = text.wrappedValue.isEmpty
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            textFieldWithPlaceholder
            if let hint = config.hint {
                HStack {
                    Text(hint)
                        .font(Font.medium(size: 12))
                        .foregroundStyle(colors.text.secondary.default)
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(height: config.hint == nil ? 54 : 74)
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
    
    @FocusState private var inFocus: Bool
    @State private var showSecureFieldContent = false
    private var textField: some View {
        VStack(spacing: 0) {
            if !placeholderIsOnFocus {
                placeholder(isOnFocus: false)
                    .padding(.bottom, 2)
                    .opacity(0)
            } else {
                Spacer()
            }
            if isSecureField {
                HStack {
                    Text(textFieldBinding.wrappedValue)
                        .font(Font.medium(size: 15))
                        .foregroundStyle(colors.text.primary.default)
                        .lineLimit(1)
                        .opacity(0)
                        .overlay(
                            SecureField("", text: textFieldBinding)
                                .font(Font.medium(size: 15))
                                .foregroundStyle(Color.clear)
                                .focused($inFocus)
                                .padding(.trailing, -2)
                            
                        )
                        .background(
                            Text(
                                showSecureFieldContent
                                    ? textFieldBinding.wrappedValue
                                    : textFieldBinding.wrappedValue.map({ _ in "*" }).joined()
                                
                            )
                            .contentTransition(.numericText(countsDown: !showSecureFieldContent))
                            .font(Font.medium(size: 15))
                            .foregroundStyle(colors.text.primary.default)
                            .multilineTextAlignment(.leading)
                            .opacity(1)
                            .lineLimit(1)
                        )
                        .foregroundColor(Color(UIColor.clear))
                    Spacer()
                }
            } else {
                textFieldWithStyle(
                    SwiftUI.TextField("", text: textFieldBinding)
                        .focused($inFocus)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(colors.background.secondary.default)
        .clipShape(.rect(cornerRadius: paddings.corners.medium))
        .overlay {
            if isSecureField {
                HStack {
                    Spacer()
                    SwiftUI.Button {
                        withAnimation(.easeInOut.speed(2)) {
                            showSecureFieldContent = !showSecureFieldContent
                        }
                    } label: {
                        Image.eye
                            .foregroundStyle(colors.icon.secondary.default)
                    }
                    .frame(width: 24, height: 24)
                    Spacer()
                        .frame(width: 16)
                }
            } else {
                EmptyView()
            }
        }
        .onTapGesture {
            inFocus = true
        }
    }
    
    func textFieldWithStyle(_ content: some View) -> some View {
        content
            .font(Font.medium(size: 15))
            .foregroundStyle(colors.text.primary.default)
            .autocorrectionDisabled(autocorrectionDisabled)
            .textContentType(contentType)
            .textInputAutocapitalization(TextInputAutocapitalization(autocapitalization))
            .keyboardType(keyboardType)
    }
    
    private var textFieldBinding: Binding<String> {
        Binding(get: {
            text
        }, set: { newValue in
            if placeholderIsOnFocus != newValue.isEmpty {
                withAnimation(.default.speed(4)) {
                    placeholderIsOnFocus = newValue.isEmpty
                }
            }
            text = newValue
        })
    }
    
    private func placeholder(isOnFocus: Bool) -> some View {
        Text(config.placeholder)
            .font(Font.medium(size: isOnFocus ? 15 : 12))
            .foregroundStyle(colors.text.secondary.default)
            .padding(.top, isOnFocus ? 0 : 8)
    }
    
    private var contentType: UITextContentType? {
        switch config.content {
        case .email:
            .username
        case .password:
            .password
        case .newPassword:
            .newPassword
        case .oneTimeCode:
            .oneTimeCode
        case .numberPad, .displayName, .unspecified:
            .none
        }
    }
    
    private var autocapitalization: UITextAutocapitalizationType {
        switch config.content {
        case .password, .newPassword, .email, .numberPad, .displayName, .oneTimeCode:
            .none
        case .unspecified:
            .sentences
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch config.content {
        case .email:
            .emailAddress
        case .numberPad:
            .decimalPad
        case .oneTimeCode:
            .numberPad
        case .unspecified, .password, .newPassword, .displayName:
            .default
        }
    }
    
    private var autocorrectionDisabled: Bool {
        switch config.content {
        case .email, .password, .newPassword, .numberPad, .displayName, .oneTimeCode:
            true
        case .unspecified:
            false
        }
    }
    
    var isSecureField: Bool {
        switch config.content {
        case .password, .newPassword:
            true
        case .email, .displayName, .oneTimeCode, .numberPad, .unspecified:
            false
        }
    }
}

#Preview {
    TextField(text: .constant("Text"), config: TextField.Config(placeholder: "Placeholder", hint: "123"))
        .environment(ColorPalette.light)
        .environment(PaddingsPalette.default)
        .loadCustomFonts()
}
