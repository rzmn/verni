import SwiftUI

public struct NavigationBar: View {
    public typealias ItemConfig = IconButton.Config
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
        
        public init(leftItem: Item? = nil, rightItem: Item? = nil, title: LocalizedStringKey, style: Style) {
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
                IconButton(
                    config: item.config,
                    action: item.action
                )
                .padding(.leading, 2)
                .padding(.top, 1)
            }
            Spacer()
            if let item = config.rightItem {
                IconButton(
                    config: item.config,
                    action: item.action
                )
                .padding(.trailing, 2)
                .padding(.top, 2)
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
