import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol AppCommon {
    var localEmailValidationUseCase: EmailValidationUseCase { get }
    var localPasswordValidationUseCase: PasswordValidationUseCase { get }

    var avatarsRepository: AvatarsRepository { get }
    var saveCredentialsUseCase: SaveCredendialsUseCase { get }
}

public protocol AppCommonCovertible {
    var appCommon: AppCommon { get }
}

public protocol DIContainer: AppCommonCovertible {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer: AppCommonCovertible {
    var userId: User.ID { get }

    var profileRepository: ProfileRepository { get }
    var usersRepository:  UsersRepository { get }
    var spendingsRepository: SpendingsRepository { get }
    var friendListRepository: FriendsRepository { get }

    var logoutUseCase: LogoutUseCase { get }

    func spendingsOfflineRepository() -> SpendingsOfflineRepository
    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func profileEditingUseCase() -> ProfileEditingUseCase
    func friendsOfflineRepository() -> FriendsOfflineRepository
    func profileOfflineRepository() -> ProfileOfflineRepository
    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func usersOfflineRepository() -> UsersOfflineRepository
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
    func receivingPushUseCase() -> ReceivingPushUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}

public protocol ActiveSessionDIContainerConvertible {
    var activeSessionDIContainer: ActiveSessionDIContainer { get }
}
