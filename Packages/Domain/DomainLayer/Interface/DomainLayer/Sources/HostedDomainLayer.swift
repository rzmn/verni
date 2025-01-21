import Entities
import ProfileRepository
import UsersRepository
import SpendingsRepository
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

    var logoutUseCase: LogoutUseCase { get }

    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
//    func receivingPushUseCase() -> ReceivingPushUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
