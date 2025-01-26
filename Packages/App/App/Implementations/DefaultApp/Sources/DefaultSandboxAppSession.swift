import App
import AppBase
import AuthWelcomeScreen
import LogInScreen
import DomainLayer
internal import DefaultAuthWelcomeScreen

@MainActor final class DefaultSandboxAppSession: SandboxAppSession {
    let auth: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions>
    var logIn: any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition> {
        _logIn
    }
    private(set) var _logIn: (any ScreenProvider<LogInEvent<AnyHostedAppSession>, LogInView<AnyHostedAppSession>, ModalTransition>)!
    let shared: any SharedAppSession
    
    init(shared: SharedAppSession, session: SandboxDomainLayer) async {
        self.shared = shared
        auth = await DefaultAuthWelcomeFactory(
            logger: session.infrastructure.logger
                .with(scope: .auth)
        ).create()
        _logIn = await LogInModel(
            session: self,
            authUseCase: session.authUseCase(),
            emailValidationUseCase: session.localEmailValidationUseCase,
            passwordValidationUseCase: session.localPasswordValidationUseCase,
            saveCredentialsUseCase: session.saveCredentialsUseCase,
            logger: session.infrastructure.logger
                .with(scope: .auth)
        )
    }
}
