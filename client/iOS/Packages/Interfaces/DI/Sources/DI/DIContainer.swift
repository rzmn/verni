import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol DIContainer {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer {
    func logoutUseCase() -> LogoutUseCase
    func spendingsRepository() -> SpendingsRepository
    func spendingInteractionsUseCase() -> SpendingInteractionsUseCase
    func friendListRepository() -> FriendsRepository
    func usersRepository() -> UsersRepository
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
