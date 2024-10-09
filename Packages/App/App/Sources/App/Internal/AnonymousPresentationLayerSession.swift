import DI
import AppBase
internal import SignInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let signInScreen: any ScreenProvider<SignInEvent, SignInView>

    init(di: AnonymousDomainLayerSession) async {
        signInScreen = await DefaultSignInFactory(di: di).create()
    }
}
