import DI
import AppBase
internal import AuthWelcomeScreen
internal import LogInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView>
    let logInScreen: any ScreenProvider<LogInEvent, LogInView>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        authWelcomeScreen = await DefaultAuthWelcomeFactory(di: di, haptic: haptic).create()
        logInScreen = await DefaultLogInFactory(di: di, haptic: haptic).create()
    }
}
