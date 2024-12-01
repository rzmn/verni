import SwiftUI

public struct BottomBarTab: Equatable {
    public let id: String
    public let icon: Image
    public let selectedIcon: Image
    
    public init(id: String, icon: Image, selectedIcon: Image) {
        self.id = id
        self.icon = icon
        self.selectedIcon = selectedIcon
    }
}

public enum BottomBarItem {
    case tab(BottomBarTab)
    case action(Image, () -> Void)
}

public struct BottomBarConfig {
    let items: [BottomBarItem]
    
    public init(items: [BottomBarItem]) {
        self.items = items
    }
}

private let barContentHeight: CGFloat = 107
struct BottomBar: View {
    @Environment(ColorPalette.self) var colors
    private let items: [AnyIdentifiable<BottomBarItem>]
    private let config: BottomBarConfig
    @Binding var tab: BottomBarTab
    
    init(config: BottomBarConfig, tab: Binding<BottomBarTab>) {
        items = config.items.enumerated().map { index, item in
            AnyIdentifiable(value: item, id: "\(index)")
        }
        self.config = config
        _tab = tab
    }
    
    var body: some View {
        HStack {
            ForEach(items) { item in
                itemView(item.value)
            }
        }
        .frame(height: barContentHeight)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(
                        color: .clear,
                        location: 0
                    ),
                    Gradient.Stop(
                        color: colors.background.primary.default,
                        location: 0.5
                    )
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    @ViewBuilder private func itemView(_ item: BottomBarItem) -> some View {
        HStack {
            Spacer()
            switch item {
            case .tab(let tab):
                (tab == self.tab ? tab.selectedIcon : tab.icon)
                    .foregroundStyle(colors.icon.primary.default)
                    .frame(width: itemSize, height: itemSize)
                    .onTapGesture {
                        self.tab = tab
                    }
            case .action(let image, _):
                image
                    .foregroundStyle(colors.icon.primary.staticLight)
                    .frame(width: itemSize, height: itemSize)
                    .background(colors.background.brand.static)
                    .clipShape(.rect(cornerRadius: itemSize / 2))
            }
            Spacer()
        }
    }
    
    private var itemSize: CGFloat {
        54
    }
}

struct BottomBarModifier: ViewModifier {
    private let config: BottomBarConfig
    @Binding var tab: BottomBarTab
    
    init(config: BottomBarConfig, tab: Binding<BottomBarTab>) {
        self.config = config
        _tab = tab
    }
    
    func body(content: Content) -> some View {
        VStack(spacing: -barContentHeight * 0.7) {
            content
            BottomBar(config: config, tab: $tab)
        }
    }
}

extension View {
    public func bottomBar(config: BottomBarConfig, tab: Binding<BottomBarTab>) -> some View {
        modifier(BottomBarModifier(config: config, tab: tab))
    }
}

#Preview {
    Color.gray
        .bottomBar(
            config: BottomBarConfig(
                items: [
                    .tab(BottomBarTab(id: "home", icon: .homeBorder, selectedIcon: .homeFill)),
                    .action(.plus, {}),
                    .tab(BottomBarTab(id: "user", icon: .userCircleBorder, selectedIcon: .userFill)),
                ]
            ),
            tab: .constant(BottomBarTab(id: "home", icon: .homeBorder, selectedIcon: .homeFill))
        )
        .environment(ColorPalette.dark)
}
