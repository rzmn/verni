import AppLayer
import UIKit
import Entities
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import LogInScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
import DesignSystem
internal import Logging
internal import Convenience

actor LogInModel {
    private let store: Store<LogInState, LogInAction<AnyHostedAppSession>>

    init(
        session: SandboxAppSession,
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        pushRegistry: PushRegistry,
        logger: Logger
    ) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: LoginSideEffects(
                store: store,
                session: session,
                authUseCase: authUseCase,
                emailValidationUseCase: emailValidationUseCase,
                passwordValidationUseCase: passwordValidationUseCase,
                saveCredentialsUseCase: saveCredentialsUseCase,
                pushRegistry: pushRegistry
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
        handler: @escaping @MainActor (LogInEvent<AnyHostedAppSession>) -> Void
    ) -> (ModalTransition) -> LogInView<AnyHostedAppSession> {
        return { transition in
            LogInView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(LogInEvent<AnyHostedAppSession>.self)",
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
