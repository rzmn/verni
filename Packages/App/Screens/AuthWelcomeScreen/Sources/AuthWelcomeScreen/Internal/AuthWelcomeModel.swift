import UIKit
import Domain
import DI
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
internal import Base
internal import DesignSystem

actor AuthWelcomeModel {
    private let store: Store<AuthWelcomeState, AuthWelcomeAction>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
    }
}

@MainActor extension AuthWelcomeModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (AuthWelcomeEvent) -> Void
    ) -> AuthWelcomeView {
        AuthWelcomeView(
            store: tap(store) { store in
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
            }
        )
    }
}
