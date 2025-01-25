import UIKit
import Entities
import AppBase
import Combine
import SwiftUI
import DebugMenuScreen
internal import Convenience
internal import DesignSystem

@MainActor final class DebugMenuModel {
    private let store: Store<DebugMenuState, DebugMenuAction>

    init() {
        store = Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension DebugMenuModel: ScreenProvider {
    typealias Args = Void

    func instantiate(
        handler: @escaping @MainActor (DebugMenuEvent) -> Void
    ) -> (Args) -> DebugMenuView {
        return { _ in
            DebugMenuView(
                store: modify(self.store) { store in
                    let store = store
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(DebugMenuEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onTapBack where store.state.section == nil:
                                    handler(.dismiss)
                                default:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                }
            )
        }
    }
}
