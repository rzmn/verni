import AppLayer
import AppBase
import ProfileScreen
import SpendingsScreen
import AddExpenseScreen
import SpendingsGroupScreen
import DomainLayer
import DesignSystem
import Foundation
import Entities
internal import LoggingExtensions
internal import DefaultProfileScreen
internal import DefaultUserPreviewScreen
internal import DefaultSpendingsScreen
internal import DefaultAddExpenseScreen
internal import DefaultSpendingsGroupScreen
internal import DefaultProfileEditingScreen

final class DefaultHostedAppSession: HostedAppSession {
    var userPreview: (User) async -> any UserPreviewScreenProvider
    var images: AvatarView.Repository
    var sandbox: any SandboxAppSession
    var profile: any ProfileScreenProvider
    var spendings: any SpendingsScreenProvider
    var addExpense: any AddExpenseScreenProvider
    var spendingsGroup: (SpendingGroup.Identifier) async -> any SpendingsGroupScreenProvider
    var profileEditing: any ProfileEditingScreenProvider
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
            hostId: session.profileRepository.profile.userId,
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
        self.userPreview = { user in
            await DefaultUserPreviewFactory(
                user: user,
                hostId: session.profileRepository.profile.userId,
                usersRepository: session.usersRepository,
                spendingsRepository: session.spendingsRepository,
                usersRemoteDataSource: session.usersRemoteDataSource,
                logger: logger
                    .with(scope: .userPreview)
            ).create()
        }
        self.spendingsGroup = { groupId in
            await DefaultSpendingsGroupFactory(
                spendingsRepository: session.spendingsRepository,
                usersRepository: session.usersRepository,
                hostId: session.profileRepository.profile.userId,
                groupId: groupId,
                logger: logger
                    .with(scope: .spendings)
            ).create()
        }
        self.profileEditing = await DefaultProfileEditingFactory(
            profileRepository: session.profileRepository,
            usersRepository: session.usersRepository,
            avatarsRepository: session.avatarsRepository,
            logger: logger
                .with(scope: .profileEditing)
        ).create()
    }
    
    func logout() async {
        await domain.logoutUseCase.logout()
    }
}
