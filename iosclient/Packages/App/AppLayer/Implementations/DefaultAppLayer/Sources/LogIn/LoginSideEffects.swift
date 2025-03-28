import Entities
import AppLayer
import SwiftUICore
import AppBase
import LogInScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
import DesignSystem
internal import Convenience

@MainActor final class LoginSideEffects: ActionHandler {
    private unowned let store: Store<LogInState, LogInAction<AnyHostedAppSession>>
    private unowned let session: SandboxAppSession
    private let authUseCase: any AuthUseCase<HostedDomainLayer>
    private let emailValidationUseCase: EmailValidationUseCase
    private let passwordValidationUseCase: PasswordValidationUseCase
    private let pushRegistry: PushRegistry
    private let saveCredentialsUseCase: SaveCredendialsUseCase

    var id: String {
        "\(LoginSideEffects.self)"
    }

    init(
        store: Store<LogInState, LogInAction<AnyHostedAppSession>>,
        session: SandboxAppSession,
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        pushRegistry: PushRegistry
    ) {
        self.store = store
        self.session = session
        self.authUseCase = authUseCase
        self.emailValidationUseCase = emailValidationUseCase
        self.passwordValidationUseCase = passwordValidationUseCase
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.pushRegistry = pushRegistry
    }

    func handle(_ action: LogInAction<AnyHostedAppSession>) {
        switch action {
        case .onLogInTap:
            logIn()
        default:
            break
        }
    }

    private func logIn() {
        let state = store.state
        guard !state.logInInProgress else {
            return
        }
        store.dispatch(.onLoggingInStarted)
        let credentials = Credentials(
            email: state.email,
            password: state.password
        )
        Task {
            await doLogIn(credentials: credentials)
        }
    }

    private func doLogIn(credentials: Credentials) async {
        do {
            let domain = try await authUseCase.login(
                credentials: credentials
            )
            let session = await DefaultHostedAppSession(
                sandbox: session,
                session: domain
            )
            Task {
                await saveCredentialsUseCase.save(email: credentials.email, password: credentials.password)
                await pushRegistry.attachSession(session: domain)
            }
            store.dispatch(.loggedIn(AnyHostedAppSession(value: session)))
        } catch {
            switch error {
            case .noConnection:
                store.dispatch(
                    .onUpdateBottomSheet(
                        .noConnection(
                            onRetry: { [weak self] in
                                guard let self else { return }
                                store.dispatch(.onUpdateBottomSheet(nil))
                                logIn()
                            },
                            onClose: { [weak self] in
                                guard let self else { return }
                                store.dispatch(.onUpdateBottomSheet(nil))
                            }
                        )
                    )
                )
            default:
                store.dispatch(
                    .onUpdateBottomSheet(
                        .hint(title: "[debug] login failed", subtitle: "reason: \(error)", actionTitle: .sheetClose, action: { [weak self] in
                            guard let self else { return }
                            store.dispatch(.onUpdateBottomSheet(nil))
                        })
                    )
                )
            }
            store.dispatch(.onLoggingInFailed)
        }
    }
}
