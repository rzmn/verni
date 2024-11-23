import Domain
import DI
import UIKit
import Logging
import AppBase
import SwiftUI
internal import Base
internal import AuthWelcomeScreen
internal import DesignSystem

actor AppModel {
    private var pendingPushToken: Data?
    private var currentSession: AuthenticatedDomainLayerSession? {
        didSet {
            if let currentSession, let pendingPushToken {
                self.pendingPushToken = nil
                Task.detached {
                    await currentSession
                        .pushRegistrationUseCase()
                        .registerForPush(token: pendingPushToken)
                }
            }
        }
    }
    private let store: Store<AppState, AppAction>

    @MainActor init(di: AnonymousDomainLayerSession, haptic: HapticManager) {
        store = Store(
            state: AppModel.initialState,
            reducer: AppModel.reducer
        )
        store.append(
            handler: AppSideEffects(
                store: store,
                di: di,
                haptic: haptic
            ),
            keepingUnique: true
        )
    }
}

extension AppModel: ScreenProvider {
    typealias Event = Void

    @MainActor func instantiate(handler: @escaping @MainActor (Event) -> Void) -> AppView {
        AppView(
            store: modify(store) { store in
                store.append(
                    handler: AnyActionHandler(
                        id: "\(Event.self)",
                        handleBlock: { _ in }
                    ),
                    keepingUnique: true
                )
            }
        )
    }
}

extension AppModel {
    public func registerPushToken(token: Data) async {
        if let currentSession {
            await currentSession
                .pushRegistrationUseCase()
                .registerForPush(token: token)
        } else {
            pendingPushToken = token
        }
    }

    public func handle(url: String) async {
        // stub
    }
}
