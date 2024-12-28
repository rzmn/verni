import SwiftUI
import AppBase
internal import DesignSystem

struct DebugMenuRootView: View {
    @ObservedObject var store: Store<DebugMenuState, DebugMenuAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<DebugMenuState, DebugMenuAction>) {
        self.store = store
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconButton(
                    config: IconButton.Config(
                        style: .primary,
                        icon: .arrowLeft
                    )
                ) {
                    store.dispatch(.onTapBack)
                }
                Spacer()
            }
            .overlay {
                Text(.debugMenuTitle)
                    .font(.medium(size: 15))
                    .foregroundStyle(colors.text.primary.staticLight)
            }
            VStack {
                ForEach(store.state.sections) { section in
                    DesignSystem.Button(
                        config: Button.Config(
                            style: .secondary,
                            text: titleFor(section: section),
                            icon: .right(.arrowRight)
                        )
                    ) {
                        store.dispatch(.debugMenuSectionTapped(section))
                    }
                }
                .padding(.horizontal, 16)
                Spacer()
            }
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colors.background.primary.default)
                    .edgesIgnoringSafeArea([.bottom])
            )
        }
        .background(
            colors.background.brand.static
                .ignoresSafeArea()
        )
    }

    private func titleFor(section: DebugMenuState.Section) -> LocalizedStringKey {
        switch section {
        case .designSystem:
            .designSystemSection
        }
    }
}

#Preview {
    DebugMenuRootView(
        store: Store(
            state: DebugMenuModel.initialState,
            reducer: DebugMenuModel.reducer
        )
    )
    .preview(packageClass: DebugMenuModel.self)
}
