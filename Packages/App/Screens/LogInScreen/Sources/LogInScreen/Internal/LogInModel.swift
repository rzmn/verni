import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem

actor LogInModel {
    private let store: Store<LogInState, LogInAction>

    init(di: AnonymousDomainLayerSession) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: LoginSideEffects(
                store: store,
                di: di
            ), keepingUnique: true
        )
    }
}

@MainActor extension LogInModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (LogInEvent) -> Void
    ) -> LogInView {
        LogInView(
            store: modify(store) { store in
                store.append(
                    handler: AnyActionHandler(
                        id: "\(LogInEvent.self)",
                        handleBlock: { action in
                            switch action {
                            case .onTapBack:
                                handler(.dismiss)
                            case .loggedIn(let session):
                                handler(.logIn(session))
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
