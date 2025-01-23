import SwiftUI
import AppBase
internal import DesignSystem

public struct DesignSystemView: View {
    @ObservedObject var store: Store<DebugMenuState, DebugMenuAction>
    private let state: DesignSystemState
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<DebugMenuState, DebugMenuAction>, state: DesignSystemState) {
        self.store = store
        self.state = state
    }

    public var body: some View {
        VStack {
            ForEach(state.sections) { section in
                DesignSystem.Button(
                    config: Button.Config(
                        style: .secondary,
                        text: titleFor(section: section),
                        icon: .right(.arrowRight)
                    )
                ) {
                    store.dispatch(.designSystemSectionTapped(section))
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .background(
            colors.background.primary.default
                .ignoresSafeArea()
        )
    }

    private func titleFor(section: DesignSystemState.Section) -> LocalizedStringKey {
        switch section {
        case .button:
            .buttonsSection
        case .textField:
            .textFieldsSection
        case .colors:
            .colorsSection
        case .fonts:
            .fontsSection
        case .haptic:
            .hapticSection
        case .popups:
            .popupsSection
        }
    }
}

#Preview {
    DesignSystemView(
        store: Store(
            state: DebugMenuModel.initialState,
            reducer: DebugMenuModel.reducer
        ),
        state: DebugMenuModel.initialDesignSystemState
    )
    .preview(packageClass: DebugMenuModel.self)
}
