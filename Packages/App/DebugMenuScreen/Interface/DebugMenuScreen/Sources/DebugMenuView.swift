import SwiftUI
import AppBase
internal import DesignSystem

public struct DebugMenuView: View {
    @ObservedObject var store: Store<DebugMenuState, DebugMenuAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    init(store: Store<DebugMenuState, DebugMenuAction>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(
            path: Binding(get: {
                store.state.navigation
            }, set: { stack in
                store.dispatch(.updateNavigationStack(stack))
            })
        ) {
            DebugMenuRootView(store: store)
                .navigationDestination(for: StackMember.self) { stackMember in
                    switch stackMember {
                    case .designSystem:
                        if case .designSystem(let state) = store.state.section {
                            DesignSystemView(store: store, state: state)
                        } else {
                            let _ = assertionFailure()
                            DesignSystemView(store: store, state: DebugMenuModel.initialDesignSystemState)
                        }
                    case .buttons:
                        ButtonsView()
                    case .textFields:
                        TextFieldsView()
                    case .colors:
                        ColorsView()
                    case .fonts:
                        FontsView()
                    case .haptic:
                        HapticView()
                    case .popups:
                        PopupsView()
                    }
                }
        }

    }
}

#Preview {
    DebugMenuView(
        store: Store(
            state: DebugMenuModel.reducer(DebugMenuModel.initialState, .debugMenuSectionTapped(.designSystem(DebugMenuModel.initialDesignSystemState))),
            reducer: DebugMenuModel.reducer
        )
    )
    .preview(packageClass: DebugMenuModel.self)
}
