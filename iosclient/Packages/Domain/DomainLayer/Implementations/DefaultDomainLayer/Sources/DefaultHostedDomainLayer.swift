import DomainLayer
import Entities
import UsersRepository
import SpendingsRepository
import LogoutUseCase
import ProfileRepository
import AsyncExtensions
import DataLayer
import QrInviteUseCase
import EmailConfirmationUseCase
import PushRegistrationUseCase
import AvatarsRepository
import Logging
internal import LoggingExtensions
internal import DefaultLogoutUseCaseImplementation
internal import DefaultProfileRepository
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultUsersRepository
internal import DefaultSpendingsRepository
internal import DefaultQRInviteUseCaseImplementation
internal import DefaultEmailConfirmationUseCaseImplementation
internal import DefaultPushRegistrationUseCaseImplementation
internal import Convenience

final class DefaultHostedDomainLayer: Sendable {
    let userId: User.Identifier
    let profileRepository: ProfileRepository
    let usersRepository: UsersRepository
    let spendingsRepository: SpendingsRepository
    let logoutUseCase: LogoutUseCase
    let avatarsRemoteDataSource: AvatarsRemoteDataSource
    let usersRemoteDataSource: UsersRemoteDataSource
    let logger: Logger

    private let dataSession: DataSession
    private let sharedDomain: DefaultSharedDomainLayer
    
    init(
        sharedDomain: DefaultSharedDomainLayer,
        logoutSubject: EventPublisher<Void>,
        sessionHost: SessionHost,
        dataSession: DataSession,
        userId: User.Identifier
    ) async {
        self.sharedDomain = sharedDomain
        self.dataSession = dataSession
        self.userId = userId
        self.logger = sharedDomain.infrastructure.logger
            .with(scope: .domainLayer(.hosted))
        self.logoutUseCase = await DefaultLogoutUseCase(
            shouldLogout: logoutSubject,
            taskFactory: sharedDomain.infrastructure.taskFactory,
            logoutPerformer: sessionHost,
            logger: logger.with(
                scope: .logout
            )
        )
        self.profileRepository = await DefaultProfileRepository(
            infrastructure: sharedDomain.infrastructure,
            userId: userId,
            api: dataSession.api,
            sync: dataSession.sync,
            logger: logger.with(
                scope: .profile
            )
        )
        self.usersRepository = await DefaultUsersRepository(
            userId: userId,
            sync: dataSession.sync,
            infrastructure: sharedDomain.infrastructure,
            logger: logger.with(
                scope: .users
            )
        )
        self.usersRemoteDataSource = DefaultUsersRemoteDataSource(
            api: dataSession.api,
            logger: logger.with(
                scope: .users
            )
        )
        self.avatarsRemoteDataSource = DefaultAvatarsRemoteDataSource(
            logger: logger.with(
                scope: .images
            ),
            fileManager: sharedDomain.infrastructure.fileManager,
            api: dataSession.api
        )
        self.spendingsRepository = await DefaultSpendingsRepository(
            userId: userId,
            sync: dataSession.sync,
            infrastructure: sharedDomain.infrastructure,
            logger: logger.with(
                scope: .spendings
            )
        )
    }
}

extension DefaultHostedDomainLayer: Loggable {}

extension DefaultHostedDomainLayer: HostedDomainLayer {
    func pushRegistrationUseCase() -> PushRegistrationUseCase {
        DefaultPushRegistrationUseCase(
            api: dataSession.api,
            logger: logger
                .with(scope: .pushNotifications)
        )
    }
    
    func emailConfirmationUseCase() -> EmailConfirmationUseCase {
        DefaultEmailConfirmationUseCase(
            api: dataSession.api,
            logger: logger
                .with(scope: .emailConfirmation)
        )
    }
    
    func qrInviteUseCase() -> QRInviteUseCase {
        DefaultQRInviteUseCase(
            logger: logger
                .with(scope: .qrCode),
            fileManager: sharedDomain.infrastructure.fileManager
        ) { userId in
            AppUrl.users(.show(id: userId)).url
        }
    }
    
    var shared: SharedDomainLayer {
        sharedDomain
    }
}
