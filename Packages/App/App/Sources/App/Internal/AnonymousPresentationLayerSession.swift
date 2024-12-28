import DI
import AppBase
internal import Logging
internal import AuthWelcomeScreen
internal import LogInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, AuthWelcomeTransitions>
    let logInScreen: any ScreenProvider<LogInEvent, LogInView, ModalTransition>
    private let logger: Logger

    init(di: AnonymousDomainLayerSession) async {
        self.logger = di.appCommon.infrastructure.logger.with(prefix: "💅🏿")
        authWelcomeScreen = await DefaultAuthWelcomeFactory(
            di: di,
            logger: logger.with(
                prefix: "👋"
            )
        ).create()
        logInScreen = await DefaultLogInFactory(
            di: di,
            logger: logger.with(
                prefix: "🔑"
            )
        ).create()
    }
}
