import AppLayer
import AppBase
import ProfileScreen
import SpendingsScreen
import DomainLayer
internal import LoggingExtensions
internal import DefaultProfileScreen
internal import DefaultSpendingsScreen

final class DefaultHostedAppSession: HostedAppSession {
    var sandbox: any SandboxAppSession
    var profile: any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
    var spendings: any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
    private let domain: HostedDomainLayer
    
    init(sandbox: SandboxAppSession, session: HostedDomainLayer) async {
        domain = session
        self.sandbox = sandbox
        let logger = session.infrastructure.logger
            .with(scope: .appLayer(.hosted))
        self.profile = await DefaultProfileFactory(
            profileRepository: session.profileRepository,
            usersRepository: session.usersRepository,
            qrInviteUseCase: session.qrInviteUseCase(),
            logger: logger
                .with(scope: .profile)
        ).create()
        self.spendings = await DefaultSpendingsFactory(
            spendingsRepository: session.spendingsRepository,
            usersRepository: session.usersRepository,
            logger: logger
                .with(scope: .spendings)
        ).create()
    }
    
    func logout() async {
        await domain.logoutUseCase.logout()
    }
}
