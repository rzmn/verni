import UIKit
import SwiftUI

public enum ButtonType {
    case primary
    case secondary
    case destructive
}

private struct ButtonStyle: ViewModifier {
    public let type: ButtonType
    public let enabled: Bool

    func body(content: Content) -> some View {
        content
            .fontStyle(textContentType)
            .frame(height: .palette.buttonHeight)
            .padding(.horizontal, .palette.defaultHorizontal)
            .tint(tintColor)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 10))
            .opacity(enabled ? 1 : 0.34)
    }

    private var tintColor: Color {
        switch type {
        case .primary:
            .palette.buttonText
        case .secondary:
            .palette.accent
        case .destructive:
            .palette.buttonText
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .primary:
            .palette.accent
        case .secondary:
            .clear
        case .destructive:
            .palette.destructive
        }
    }

    private var textContentType: TextContentType {
        switch type {
        case .primary, .secondary, .destructive:
            .button
        }
    }
}

extension View {
    public func buttonStyle(
        type: ButtonType,
        enabled: Bool
    ) -> some View {
        modifier(ButtonStyle(type: type, enabled: enabled))
    }
}

#Preview {
    HStack {
        Spacer()
        VStack {
            Spacer()

            Button {} label: { Text("primary") }
            .buttonStyle(type: .primary, enabled: true)

            Button {} label: { Text("secondary") }
            .buttonStyle(type: .secondary, enabled: true)

            Button {} label: { Text("destructive") }
            .buttonStyle(type: .destructive, enabled: true)

            Button {} label: { Text("primary") }
            .buttonStyle(type: .primary, enabled: false)

            Button {} label: { Text("secondary") }
            .buttonStyle(type: .secondary, enabled: false)

            Button {} label: { Text("destructive") }
            .buttonStyle(type: .destructive, enabled: false)

            Spacer()
        }
        Spacer()
    }
    .ignoresSafeArea()
    .background(Color.palette.background)
}
