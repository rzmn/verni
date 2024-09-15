import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol AppCommon: Sendable {
    var localEmailValidationUseCase: EmailValidationUseCase { get }
    var localPasswordValidationUseCase: PasswordValidationUseCase { get }

    var avatarsRepository: AvatarsRepository { get }
    var saveCredentialsUseCase: SaveCredendialsUseCase { get }
}

public protocol AppCommonCovertible: Sendable {
    var appCommon: AppCommon { get }
}

public protocol DIContainer: AppCommonCovertible, Sendable {
    func authUseCase() async -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer: AppCommonCovertible {
    var userId: User.ID { get }

    var profileRepository: any ProfileRepository { get }
    var usersRepository:  UsersRepository { get }
    var spendingsRepository: SpendingsRepository { get }
    var friendListRepository: FriendsRepository { get }

    var spendingsOfflineRepository: SpendingsOfflineRepository { get }
    var friendsOfflineRepository: FriendsOfflineRepository { get }
    var profileOfflineRepository: ProfileOfflineRepository { get }
    var usersOfflineRepository: UsersOfflineRepository { get }

    var logoutUseCase: LogoutUseCase { get }

    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func profileEditingUseCase() -> ProfileEditingUseCase
    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
    func receivingPushUseCase() -> ReceivingPushUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}

public protocol ActiveSessionDIContainerConvertible: Sendable {
    func activeSessionDIContainer() async -> ActiveSessionDIContainer
}
