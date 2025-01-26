import Entities
import UIKit
import AppBase
import SwiftUI
import AppLayer
import DomainLayer
import AuthWelcomeScreen
internal import Logging
internal import Convenience
internal import DesignSystem

actor AppModel {
    private var pendingPushToken: Data?
    private var currentSession: HostedDomainLayer? {
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

    @MainActor init(
        domain: @Sendable @escaping () async -> SandboxDomainLayer
    ) {
        store = Store(
            state: AppModel.initialState,
            reducer: AppModel.reducer
        )
        store.append(
            handler: AppSideEffects(
                store: store,
                domain: domain
            ),
            keepingUnique: true
        )
    }
}

extension AppModel: AppFactory {
    @MainActor func view() -> AppView {
        AppView(store: self.store)
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
