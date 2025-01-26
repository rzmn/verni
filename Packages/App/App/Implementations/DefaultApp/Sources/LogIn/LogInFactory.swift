import App
import AppBase
import LogInScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
internal import Logging

final class DefaultLogInFactory {
    @MainActor var sandbox: SandboxAppSession!
    private let authUseCase: any AuthUseCase<HostedDomainLayer>
    private let emailValidationUseCase: EmailValidationUseCase
    private let passwordValidationUseCase: PasswordValidationUseCase
    private let saveCredentialsUseCase: SaveCredendialsUseCase
    private let logger: Logger

    init(
        authUseCase: any AuthUseCase<HostedDomainLayer>,
        emailValidationUseCase: EmailValidationUseCase,
        passwordValidationUseCase: PasswordValidationUseCase,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        logger: Logger
    ) {
        self.authUseCase = authUseCase
        self.emailValidationUseCase = emailValidationUseCase
        self.passwordValidationUseCase = passwordValidationUseCase
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.logger = logger
    }
}

extension DefaultLogInFactory: LogInFactory {
    public func create() async -> any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition> {
        await LogInModel(
            session: sandbox,
            authUseCase: authUseCase,
            emailValidationUseCase: emailValidationUseCase,
            passwordValidationUseCase: passwordValidationUseCase,
            saveCredentialsUseCase: saveCredentialsUseCase,
            logger: logger
        )
    }
}
