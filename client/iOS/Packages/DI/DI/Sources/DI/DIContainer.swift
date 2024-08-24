import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol AppCommon {
    func localEmailValidationUseCase() -> EmailValidationUseCase
    func localPasswordValidationUseCase() -> PasswordValidationUseCase
    func avatarsRepository() -> AvatarsRepository
    func saveCredentials() -> SaveCredendialsUseCase
}

public protocol AppCommonCovertible {
    func appCommon() -> AppCommon
}

public protocol DIContainer: AppCommonCovertible {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer: AppCommonCovertible {
    var userId: User.ID { get }

    func logoutUseCase() -> LogoutUseCase
    func spendingsRepository() -> SpendingsRepository
    func spendingsOfflineRepository() -> SpendingsOfflineRepository
    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func profileEditingUseCase() -> ProfileEditingUseCase
    func friendListRepository() -> FriendsRepository
    func friendsOfflineRepository() -> FriendsOfflineRepository
    func usersRepository() -> UsersRepository
    func profileRepository() -> ProfileRepository
    func profileOfflineRepository() -> ProfileOfflineRepository
    func pushRegistrationUseCase() -> PushRegistrationUseCase
    func usersOfflineRepository() -> UsersOfflineRepository
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func emailConfirmationUseCase() -> EmailConfirmationUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
