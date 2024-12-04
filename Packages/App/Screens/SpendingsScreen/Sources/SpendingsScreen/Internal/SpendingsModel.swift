import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem

actor SpendingsModel {
    private let store: Store<SpendingsState, SpendingsAction>

    init(di: AuthenticatedDomainLayerSession) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension SpendingsModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (SpendingsEvent) -> Void
    ) -> (SpendingsTransitions) -> SpendingsView {
        return { transitions in
            SpendingsView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(SpendingsEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .onUserTap(let user):
                                    handler(.onUserTap(user))
                                default:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                },
                transitions: transitions
            )
        }
    }
}
