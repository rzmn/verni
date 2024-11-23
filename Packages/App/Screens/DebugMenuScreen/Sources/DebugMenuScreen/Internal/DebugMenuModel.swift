import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem

actor DebugMenuModel {
    private let store: Store<DebugMenuState, DebugMenuAction>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension DebugMenuModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (DebugMenuEvent) -> Void
    ) -> DebugMenuView {
        DebugMenuView(
            store: modify(store) { store in
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
