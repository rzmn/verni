import AppLayer
import AppBase
import ProfileScreen
import SpendingsScreen
import AddExpenseScreen
import DomainLayer
import DesignSystem
import Foundation
internal import LoggingExtensions
internal import DefaultProfileScreen
internal import DefaultSpendingsScreen
internal import DefaultAddExpenseScreen

final class DefaultHostedAppSession: HostedAppSession {
    var images: AvatarView.Repository
    var sandbox: any SandboxAppSession
    var profile: any ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
    var spendings: any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
    var addExpense: any ScreenProvider<AddExpenseEvent, AddExpenseView, AddExpenseTransitions>
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
        self.images = AvatarView.Repository(
            getBlock: { avatarId in
                await session.avatarsRemoteDataSource.fetch(id: avatarId)
                    .flatMap { image in
                        Data.init(base64Encoded: image.base64)
                    }
            }
        )
        self.addExpense = await DefaultAddExpenseFactory(
            profileRepository: session.profileRepository,
            usersRepository: session.usersRepository,
            spendingsRepository: session.spendingsRepository,
            logger: logger
                .with(scope: .addSpending)
        ).create()
    }
    
    func logout() async {
        await domain.logoutUseCase.logout()
    }
}
