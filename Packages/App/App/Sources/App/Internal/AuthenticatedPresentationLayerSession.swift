import DI
import AppBase
import Domain
internal import ProfileScreen
internal import SpendingsScreen

@MainActor final class AuthenticatedPresentationLayerSession: Sendable {
    let fallback: AnonymousPresentationLayerSession
    let profileScreen: any ScreenProvider<ProfileEvent, ProfileView>
    let spendingsScreen: any ScreenProvider<SpendingsEvent, SpendingsView>
    private let di: AuthenticatedDomainLayerSession
    
    init(di: AuthenticatedDomainLayerSession, fallback: AnonymousPresentationLayerSession) async {
        self.fallback = fallback
        self.di = di
        profileScreen = await DefaultProfileFactory(di: di).create()
        spendingsScreen = await DefaultSpendingsFactory(di: di).create()
    }
    
    func logout() async {
        await di.logoutUseCase.logout()
    }
}
