import SwiftUI

public struct BottomBarTab: Equatable {
    let icon: Image
    let selectedIcon: Image
    
    public init(icon: Image, selectedIcon: Image) {
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
        GeometryReader { geometry in
            VStack {
                Spacer()
                VStack {
                    HStack {
                        ForEach(items) { item in
                            itemView(item.value)
                        }
                    }
                    .frame(height: 107)
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            colors.background.primary.default
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder private func itemView(_ item: BottomBarItem) -> some View {
        HStack {
            Spacer()
            switch item {
            case .tab(let tab):
                (tab == self.tab ? tab.selectedIcon : tab.icon)
                    .foregroundStyle(colors.icon.primary.default)
                    .frame(width: itemSize, height: itemSize)
            case .action(let image, _):
                image
                    .foregroundStyle(colors.icon.primary.default)
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
        content.overlay {
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
    VStack {
        Spacer()
        BottomBar(
            config: BottomBarConfig(
                items: [
                    .tab(BottomBarTab(icon: .homeBorder, selectedIcon: .homeFill)),
                    .action(.plus, {}),
                    .tab(BottomBarTab(icon: .userCircleBorder, selectedIcon: .userFill)),
                ]
            ),
            tab: .constant(BottomBarTab(icon: .homeBorder, selectedIcon: .homeFill))
        )
    }
    .environment(ColorPalette.dark)
}
