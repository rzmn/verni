import DI
import AppBase
internal import SignInOfferScreen
internal import SignInScreen
internal import SignUpScreen

@MainActor final class AppDependencies: Sendable {
    let signInOfferScreen: any ScreenProvider<SignInOfferEvent, SignInOfferView>
    let signInScreen: any ScreenProvider<SignInEvent, SignInView>
    let signUpScreen: any ScreenProvider<SignUpEvent, SignUpView>

    init(di: DIContainer) async {
        signInOfferScreen = await DefaultSignInOfferFactory(di: di).create()
        signInScreen = await DefaultSignInFactory(di: di).create()
        signUpScreen = await DefaultSignUpFactory(di: di).create()
    }
}
