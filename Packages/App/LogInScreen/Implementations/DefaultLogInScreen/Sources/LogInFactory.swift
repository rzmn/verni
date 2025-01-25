import AppBase
import LogInScreen
import AuthUseCase
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import DomainLayer
import Logging

public final class DefaultLogInFactory {
    private let authUseCase: any AuthUseCase<HostedDomainLayer>
    private let emailValidationUseCase: EmailValidationUseCase
    private let passwordValidationUseCase: PasswordValidationUseCase
    private let saveCredentialsUseCase: SaveCredendialsUseCase
    private let logger: Logger

    public init(
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
    public func create() async -> any ScreenProvider<LogInEvent, LogInView, ModalTransition> {
        await LogInModel(
            authUseCase: authUseCase,
            emailValidationUseCase: emailValidationUseCase,
            passwordValidationUseCase: passwordValidationUseCase,
            saveCredentialsUseCase: saveCredentialsUseCase,
            logger: logger
        )
    }
}
