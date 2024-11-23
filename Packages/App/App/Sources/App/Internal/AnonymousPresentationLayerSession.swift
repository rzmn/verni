import DI
import AppBase
internal import AuthWelcomeScreen
internal import DebugMenuScreen
internal import LogInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView>
    let debugMenuScreen: any ScreenProvider<DebugMenuEvent, DebugMenuView>
    let logInScreen: any ScreenProvider<LogInEvent, LogInView>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        authWelcomeScreen = await DefaultAuthWelcomeFactory(di: di, haptic: haptic).create()
        debugMenuScreen = await DefaultDebugMenuFactory(di: di, haptic: haptic).create()
        logInScreen = await DefaultLogInFactory(di: di, haptic: haptic).create()
    }
}
