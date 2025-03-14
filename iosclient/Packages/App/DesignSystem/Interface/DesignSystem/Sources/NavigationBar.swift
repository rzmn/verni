import SwiftUI

public struct NavigationBar: View {
    public struct ButtonConfig {
        let title: LocalizedStringKey
        let enabled: Bool
        
        public init(title: LocalizedStringKey, enabled: Bool) {
            self.title = title
            self.enabled = enabled
        }
    }
    
    public enum ItemConfig {
        case icon(IconButton.Config)
        case button(ButtonConfig)
    }
    public struct Item {
        let config: ItemConfig
        let action: () -> Void

        public init(config: ItemConfig, action: @escaping () -> Void) {
            self.config = config
            self.action = action
        }
    }
    public enum Style {
        case primary
        case brand
    }
    public struct Config {
        let leftItem: Item?
        let rightItem: Item?
        let title: LocalizedStringKey
        let style: Style

        public init(
            leftItem: Item? = nil,
            rightItem: Item? = nil,
            title: LocalizedStringKey,
            style: Style
        ) {
            self.leftItem = leftItem
            self.rightItem = rightItem
            self.title = title
            self.style = style
        }
    }

    @Environment(ColorPalette.self) var colors
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        HStack {
            if let item = config.leftItem {
                switch item.config {
                case .icon(let config):
                    IconButton(
                        config: config,
                        action: item.action
                    )
                    .padding(.leading, 2)
                    .padding(.top, 1)
                case .button(let config):
                    SwiftUI.Button(action: item.action) {
                        Text(config.title)
                            .font(.medium(size: 15))
                            .foregroundStyle(colors.text.primary.default)
                            .padding(.horizontal, 15)
                            .opacity(config.enabled ? 1 : 0.5)
                            .allowsHitTesting(config.enabled)
                    }
                    .frame(height: 54)
                    .background(colors.background.primary.default)
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 2)
                }
            }
            Spacer()
            if let item = config.rightItem {
                switch item.config {
                case .icon(let config):
                    IconButton(
                        config: config,
                        action: item.action
                    )
                    .padding(.leading, 2)
                    .padding(.top, 1)
                case .button(let config):
                    SwiftUI.Button(action: item.action) {
                        Text(config.title)
                            .font(.medium(size: 15))
                            .foregroundStyle(colors.text.primary.default)
                            .padding(.horizontal, 15)
                            .opacity(config.enabled ? 1 : 0.5)
                            .allowsHitTesting(config.enabled)
                    }
                    .frame(height: 54)
                    .background(colors.background.primary.default)
                    .clipShape(.rect(cornerRadius: 16))
                    .padding(.horizontal, 2)
                }
            }
        }
        .frame(height: 56)
        .overlay {
            Text(config.title)
                .font(.medium(size: 15))
                .foregroundStyle(foregroundColor)
        }
    }

    private var foregroundColor: Color {
        switch config.style {
        case .brand:
            colors.text.primary.staticLight
        case .primary:
            colors.text.primary.default
        }
    }
}
