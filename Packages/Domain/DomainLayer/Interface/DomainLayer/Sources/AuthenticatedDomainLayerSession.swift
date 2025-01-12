import Domain

public protocol AuthenticatedDomainLayerSession: AppCommonCovertible {
    var userId: User.Identifier { get }

    var profileRepository: any ProfileRepository { get }
    var usersRepository: UsersRepository { get }
    var spendingsRepository: SpendingsRepository { get }

    var spendingsOfflineRepository: SpendingsOfflineRepository { get }
    var profileOfflineRepository: ProfileOfflineRepository { get }
    var usersOfflineRepository: UsersOfflineRepository { get }

    var logoutUseCase: LogoutUseCase { get }

    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func profileEditingUseCase() -> ProfileEditingUseCase
    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
    func receivingPushUseCase() -> ReceivingPushUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
