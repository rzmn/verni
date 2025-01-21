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
internal import DefaultLogoutUseCaseImplementation
internal import DefaultProfileRepository
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

    private let dataSession: DataSession
    private let sharedDomain: DefaultSharedDomainLayer
    
    init(
        sharedDomain: DefaultSharedDomainLayer,
        logoutSubject: AsyncSubject<Void>,
        sessionHost: SessionHost,
        dataSession: DataSession,
        userId: User.Identifier
    ) async {
        self.sharedDomain = sharedDomain
        self.dataSession = dataSession
        self.userId = userId
        
        let logger = sharedDomain.infrastructure.logger
        self.logoutUseCase = await DefaultLogoutUseCase(
            shouldLogout: logoutSubject,
            taskFactory: sharedDomain.infrastructure.taskFactory,
            logoutPerformer: sessionHost,
            logger: logger.with(
                prefix: "🚪"
            )
        )
        self.profileRepository = await DefaultProfileRepository(
            infrastructure: sharedDomain.infrastructure,
            userId: userId,
            api: dataSession.api,
            sync: dataSession.sync,
            logger: logger.with(
                prefix: "🆔"
            )
        )
        self.usersRepository = await DefaultUsersRepository(
            userId: userId,
            sync: dataSession.sync,
            infrastructure: sharedDomain.infrastructure,
            logger: logger.with(
                prefix: "🪪"
            )
        )
        self.spendingsRepository = await DefaultSpendingsRepository(
            userId: userId,
            sync: dataSession.sync,
            infrastructure: sharedDomain.infrastructure,
            logger: logger.with(
                prefix: "💸"
            )
        )
    }
    
}

extension DefaultHostedDomainLayer: HostedDomainLayer {
    func pushRegistrationUseCase() -> PushRegistrationUseCase {
        DefaultPushRegistrationUseCase(
            api: dataSession.api,
            logger: shared.infrastructure.logger
                .with(prefix: "🔔")
        )
    }
    
    func emailConfirmationUseCase() -> EmailConfirmationUseCase {
        DefaultEmailConfirmationUseCase(
            api: dataSession.api,
            logger: shared.infrastructure.logger
                .with(prefix: "📧")
        )
    }
    
    func qrInviteUseCase() -> QRInviteUseCase {
        DefaultQRInviteUseCase(
            logger: shared.infrastructure.logger
                .with(prefix: "🌃")
        ) { userId in
            AppUrl.users(.show(id: userId)).url
        }
    }
    
    var shared: SharedDomainLayer {
        sharedDomain
    }
}
