import DI
import AppBase
internal import AuthWelcomeScreen
internal import LogInScreen

@MainActor final class AnonymousPresentationLayerSession: Sendable {
    let authWelcomeScreen: any ScreenProvider<AuthWelcomeEvent, AuthWelcomeView, TwoSideTransition<BottomSheetTransition, BottomSheetTransition>>
    let logInScreen: any ScreenProvider<LogInEvent, LogInView, BottomSheetTransition>

    init(di: AnonymousDomainLayerSession) async {
        authWelcomeScreen = await DefaultAuthWelcomeFactory(di: di).create()
        logInScreen = await DefaultLogInFactory(di: di).create()
    }
}
