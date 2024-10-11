import DI
import AppBase
internal import SignInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let signInScreen: any ScreenProvider<SignInEvent, SignInView>

    init(di: AnonymousDomainLayerSession, haptic: HapticManager) async {
        signInScreen = await DefaultSignInFactory(di: di, haptic: haptic).create()
    }
}
