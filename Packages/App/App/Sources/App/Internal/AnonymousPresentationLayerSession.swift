import DI
import AppBase
internal import AuthWelcomeScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        authWelcomeScreen = await DefaultAuthWelcomeFactory(di: di, haptic: haptic).create()
    }
}
