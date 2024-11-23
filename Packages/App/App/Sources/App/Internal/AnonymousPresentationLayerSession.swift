import DI
import AppBase
internal import AuthWelcomeScreen
internal import DebugMenuScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView>
    let debugMenuScreen: any ScreenProvider<DebugMenuEvent, DebugMenuView>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        authWelcomeScreen = await DefaultAuthWelcomeFactory(di: di, haptic: haptic).create()
        debugMenuScreen = await DefaultDebugMenuFactory(di: di, haptic: haptic).create()
    }
}
