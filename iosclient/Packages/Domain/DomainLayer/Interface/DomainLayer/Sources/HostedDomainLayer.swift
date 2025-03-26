import Entities
import AvatarsRepository
import ProfileRepository
import UsersRepository
import SpendingsRepository
import OperationsRepository
import LogoutUseCase
import PushRegistrationUseCase
import IncomingPushUseCase
import EmailConfirmationUseCase
import QrInviteUseCase

public protocol HostedDomainLayer: SharedDomainLayerCovertible {
    var userId: User.Identifier { get }

    var profileRepository: ProfileRepository { get }
    var usersRepository: UsersRepository { get }
    var spendingsRepository: SpendingsRepository { get }
    var avatarsRepository: AvatarsRepository { get }
    var operationsRepository: OperationsRepository { get }
    
    var usersRemoteDataSource: UsersRemoteDataSource { get }
    var avatarsRemoteDataSource: AvatarsRemoteDataSource { get }

    var logoutUseCase: LogoutUseCase { get }

    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
//    func receivingPushUseCase() -> ReceivingPushUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
