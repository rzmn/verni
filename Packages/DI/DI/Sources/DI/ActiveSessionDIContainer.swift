import Domain

public protocol ActiveSessionDIContainer: AppCommonCovertible {
    var userId: User.Identifier { get }

    var profileRepository: any ProfileRepository { get }
    var usersRepository: UsersRepository { get }
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
