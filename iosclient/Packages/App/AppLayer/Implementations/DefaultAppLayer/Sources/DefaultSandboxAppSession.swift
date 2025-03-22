import AppLayer
import AppBase
import AuthWelcomeScreen
import LogInScreen
import SignUpScreen
import DomainLayer
internal import LoggingExtensions
internal import DefaultAuthWelcomeScreen

@MainActor final class DefaultSandboxAppSession: SandboxAppSession {
    let auth: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions>
    var logIn: any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition> {
        _logIn
    }
    var signUp: any ScreenProvider<SignUpEvent<AnyHostedAppSession>, SignUpView<AnyHostedAppSession>, ModalTransition> {
        _signUp
    }
    private(set) var _logIn: (any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition>)!
    private(set) var _signUp: (any ScreenProvider<SignUpEvent<AnyHostedAppSession>, SignUpView<AnyHostedAppSession>, ModalTransition>)!
    let shared: any SharedAppSession
    
    init(shared: SharedAppSession, session: SandboxDomainLayer) async {
        self.shared = shared
        let logger = session.infrastructure.logger
            .with(scope: .appLayer(.sandbox))
        auth = await DefaultAuthWelcomeFactory(
            logger: logger
                .with(scope: .auth)
        ).create()
        _logIn = await LogInModel(
            session: self,
            authUseCase: session.authUseCase(),
            emailValidationUseCase: session.localEmailValidationUseCase,
            passwordValidationUseCase: session.localPasswordValidationUseCase,
            saveCredentialsUseCase: session.saveCredentialsUseCase,
            logger: logger
                .with(scope: .logIn)
        )
        _signUp = await SignUpModel(
            session: self,
            authUseCase: session.authUseCase(),
            emailValidationUseCase: session.localEmailValidationUseCase,
            passwordValidationUseCase: session.localPasswordValidationUseCase,
            saveCredentialsUseCase: session.saveCredentialsUseCase,
            logger: logger
                .with(scope: .signUp)
        )
    }
}
