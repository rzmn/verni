import DI
import AppBase
import Domain
internal import ProfileScreen
internal import SpendingsScreen

@MainActor final class AuthenticatedPresentationLayerSession: Sendable {
    let fallback: AnonymousPresentationLayerSession
    let profileScreen: any ScreenProvider<ProfileEvent, ProfileView>
    let spendingsScreen: any ScreenProvider<SpendingsEvent, SpendingsView>
    
    init(di: AuthenticatedDomainLayerSession, fallback: AnonymousPresentationLayerSession, haptic: HapticManager = DefaultHapticManager()) async {
        self.fallback = fallback
        profileScreen = await DefaultProfileFactory(di: di, haptic: haptic).create()
        spendingsScreen = await DefaultSpendingsFactory(di: di, haptic: haptic).create()
    }
}
