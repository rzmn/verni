import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import Logging
internal import Base
internal import DesignSystem

actor AuthWelcomeModel {
    private let store: Store<AuthWelcomeState, AuthWelcomeAction>

    init(di: AnonymousDomainLayerSession, logger: Logger) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: AnyActionHandler(
                id: "\(Logger.self)",
                handleBlock: { action in
                    logger.logI { "received action \(action)" }
                }
            ),
            keepingUnique: true
        )
    }
}

@MainActor extension AuthWelcomeModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (AuthWelcomeEvent) -> Void
    ) -> (AuthWelcomeTransitions) -> AuthWelcomeView {
        return { transition in
            AuthWelcomeView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(AuthWelcomeEvent.self)",
                            handleBlock: { action in
                                switch action {
                                case .logInTapped:
                                    handler(.logIn)
                                case .signUpTapped:
                                    handler(.signUp)
                                case .signInWithGoogleTapped, .signInWithAppleTapped:
                                    break
                                }
                            }
                        ),
                        keepingUnique: true
                    )
                },
                transitionFrom: transition.appear,
                transitionTo: transition.dismiss
            )
        }
    }
}
