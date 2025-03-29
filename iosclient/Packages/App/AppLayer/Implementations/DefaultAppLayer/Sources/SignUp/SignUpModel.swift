import AppLayer
import UIKit
import Entities
import AppBase
import Combine
import AsyncExtensions
import SwiftUI
import SignUpScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
import DesignSystem
internal import Logging
internal import Convenience

actor SignUpModel {
    private let store: Store<SignUpState, SignUpAction<AnyHostedAppSession>>

    init(
        session: SandboxAppSession,
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        pushRegistry: PushRegistry,
        urlProvider: UrlProvider,
        logger: Logger
    ) async {
        store = await Store(
            state: Self.initialState,
            reducer: Self.reducer
        )
        await store.append(
            handler: SignUpSideEffects(
                store: store,
                session: session,
                authUseCase: authUseCase,
                emailValidationUseCase: emailValidationUseCase,
                passwordValidationUseCase: passwordValidationUseCase,
                saveCredentialsUseCase: saveCredentialsUseCase,
                urlProvider: urlProvider,
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

@MainActor extension SignUpModel: ScreenProvider {
    func instantiate(
        handler: @escaping @MainActor (SignUpEvent<AnyHostedAppSession>) -> Void
    ) -> (ModalTransition) -> SignUpView<AnyHostedAppSession> {
        return { transition in
            SignUpView(
                store: modify(self.store) { store in
                    store.append(
                        handler: AnyActionHandler(
                            id: "\(SignUpEvent<AnyHostedAppSession>.self)",
                            handleBlock: { action in
                                switch action {
                                case .onTapBack:
                                    handler(.dismiss)
                                case .signUp(let session):
                                    handler(.signUp(session))
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
