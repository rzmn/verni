import UIKit
import Entities
import DomainLayer
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import Logging
import LogInScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
internal import Convenience
internal import DesignSystem

actor LogInModel {
    private let store: Store<LogInState, LogInAction>

    init(
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        logger: Logger
    ) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: LoginSideEffects(
                store: store,
                authUseCase: authUseCase,
                emailValidationUseCase: emailValidationUseCase,
                passwordValidationUseCase: passwordValidationUseCase,
                saveCredentialsUseCase: saveCredentialsUseCase
            ), keepingUnique: true
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

@MainActor extension LogInModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (LogInEvent) -> Void
    ) -> (ModalTransition) -> LogInView {
        return { transition in
            LogInView(
                store: modify(self.store) { store in
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
                },
                transition: transition
            )
        }
    }
}
