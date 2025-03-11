import SwiftUI
internal import DesignSystem

public struct BalanceAccessory: View {
    @Environment(ColorPalette.self) private var colors
    
    public enum Style {
        case positive
        case negative
    }
    
    private let style: Style
    
    public init(style: Style) {
        self.style = style
    }
    
    public var body: some View {
        content
            .frame(width: 20, height: 20)
            .foregroundStyle(accesoryIconForeground)
            .background(accesoryIconBackground)
            .clipShape(.rect(cornerRadius: 4))
    }
    
    private var content: some View {
        switch style {
        case .positive:
            Image.plus
        case .negative:
            Image.minus
        }
    }

    private var accesoryIconBackground: Color {
        switch style {
        case .positive:
            colors.background.positive.default
        case .negative:
            colors.background.negative.default
        }
    }

    private var accesoryIconForeground: Color {
        switch style {
        case .positive:
            colors.icon.positive.default
        case .negative:
            colors.icon.negative.default
        }
    }
}
