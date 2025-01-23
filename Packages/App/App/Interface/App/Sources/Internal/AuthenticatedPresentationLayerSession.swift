import DI
import AppBase
import Domain
internal import Logging
internal import ProfileScreen
internal import SpendingsScreen

@MainActor final class AuthenticatedPresentationLayerSession: Sendable {
    let fallback: AnonymousPresentationLayerSession
    let profileScreen: any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
    let spendingsScreen: any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
    private let logger: Logger
    private let di: AuthenticatedDomainLayerSession

    init(di: AuthenticatedDomainLayerSession, fallback: AnonymousPresentationLayerSession) async {
        self.logger = di.appCommon.infrastructure.logger.with(prefix: "💅")
        self.fallback = fallback
        self.di = di
        profileScreen = await DefaultProfileFactory(
            di: di,
            logger: logger.with(
                prefix: "👤"
            )
        ).create()
        spendingsScreen = await DefaultSpendingsFactory(
            di: di,
            logger: logger.with(
                prefix: "💰"
            )
        ).create()
    }

    func warmup() async {
        if await di.profileOfflineRepository.getProfile() == nil {
            _ = try? await di.profileRepository.refreshProfile()
        }
    }

    func logout() async {
        await di.logoutUseCase.logout()
    }
}
