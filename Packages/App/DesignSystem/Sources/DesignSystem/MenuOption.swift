import SwiftUI

public struct MenuOption: View {
    @Environment(ColorPalette.self) var colors
    
    public enum Style {
        case primary
        case destructive
    }
    
    public struct Config {
        let style: Style
        let icon: Image
        let title: LocalizedStringKey
        let accessoryIcon: Image?
        
        public init(style: Style, icon: Image, title: LocalizedStringKey, accessoryIcon: Image? = nil) {
            self.style = style
            self.icon = icon
            self.title = title
            self.accessoryIcon = accessoryIcon
        }
    }
    
    private let config: Config
    private let action: () -> Void
    
    public init(config: Config, action: @escaping () -> Void) {
        self.config = config
        self.action = action
    }
    
    public var body: some View {
        SwiftUI.Button.init(action: action) {
            HStack {
                config.icon
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                Text(config.title)
                    .foregroundStyle(textColor)
                    .font(.medium(size: 15))
                Spacer()
                if let accessoryIcon = config.accessoryIcon {
                    accessoryIcon
                        .foregroundStyle(iconColor)
                        .frame(width: 24, height: 24)
                        .padding(12)
                }
            }
            .frame(height: 48)
        }
        .frame(height: 48)
        .background(backgroundColor)
        .clipShape(.rect(cornerRadius: 24))
    }
    
    private var iconColor: Color {
        switch config.style {
        case .primary:
            colors.icon.primary.default
        case .destructive:
            colors.icon.negative.default
        }
    }
    
    private var textColor: Color {
        switch config.style {
        case .primary:
            colors.text.primary.default
        case .destructive:
            colors.text.negative.default
        }
    }
    
    private var backgroundColor: Color {
        switch config.style {
        case .primary:
            colors.background.secondary.default
        case .destructive:
            colors.background.negative.default
        }
    }
}

#Preview {
    MenuOption(
        config: MenuOption.Config(
            style: .primary,
            icon: .chevronRight,
            title: "LABEL"
        ),
        action: {}
    )
    .environment(ColorPalette.dark)
}
