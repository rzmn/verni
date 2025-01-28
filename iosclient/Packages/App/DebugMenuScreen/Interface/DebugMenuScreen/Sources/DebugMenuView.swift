import SwiftUI
import AppBase
internal import DesignSystem

public struct DebugMenuView: View {
    @ObservedObject var store: Store<DebugMenuState, DebugMenuAction>
    @Environment(PaddingsPalette.self) var paddings
    @Environment(ColorPalette.self) var colors

    public init(store: Store<DebugMenuState, DebugMenuAction>) {
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
                    case .designSystem(let state):
                        DesignSystemView(store: store, state: state)
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

class ClassToIdentifyBundle {}

#Preview {
    DebugMenuView(
        store: Store(
            state: DebugMenuState(
                navigation: [],
                sections: [
                    .designSystem(
                        DesignSystemState(
                            sections: [
                                .button,
                                .colors,
                                .fonts
                            ],
                            section: nil
                        )
                    )
                ],
                section: nil
            ),
            reducer: { state, _ in state }
        )
    )
    .preview(packageClass: ClassToIdentifyBundle.self)
}
