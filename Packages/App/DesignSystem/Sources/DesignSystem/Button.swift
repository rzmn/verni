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
            .font(font)
            .frame(height: .palette.buttonHeight)
            .padding(.horizontal, .palette.defaultHorizontal)
            .tint(tintColor)
            .background(backgroundColor)
            .clipShape(.rect(cornerRadius: 10))
    }

    private var tintColor: Color {
        switch type {
        case .primary:
            .palette.primary
        case .secondary:
            .palette.iconSecondary
        case .destructive:
            .palette.destructive
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .primary:
            .palette.backgroundContent
        case .secondary:
            .clear
        case .destructive:
            .palette.destructiveBackground
        }
    }

    private var font: Font {
        switch type {
        case .primary, .secondary, .destructive:
            .palette.title2
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
    VStack {
        Button {} label: { Text("primary") }
        .buttonStyle(type: .primary, enabled: true)

        Button {} label: { Text("secondary") }
        .buttonStyle(type: .secondary, enabled: true)

        Button {} label: { Text("destructive") }
        .buttonStyle(type: .destructive, enabled: true)
    }
}
