import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol AppCommon {
    func localEmailValidationUseCase() -> EmailValidationUseCase
    func remoteEmailValidationUseCase() -> EmailValidationUseCase
    func passwordValidationUseCase() -> PasswordValidationUseCase
}

public protocol AppCommonCovertible {
    func appCommon() -> AppCommon
}

public protocol DIContainer: AppCommonCovertible {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer: AppCommonCovertible {
    func logoutUseCase() -> LogoutUseCase
    func spendingsRepository() -> SpendingsRepository
    func spendingsOfflineRepository() -> SpendingsOfflineRepository
    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func profileEditingUseCase() -> ProfileEditingUseCase
    func friendListRepository() -> FriendsRepository
    func friendsOfflineRepository() -> FriendsOfflineRepository
    func usersRepository() -> UsersRepository
    func usersOfflineRepository() -> UsersOfflineRepository
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
