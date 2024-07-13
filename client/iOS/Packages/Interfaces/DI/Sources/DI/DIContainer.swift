import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol DIContainer {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}

public protocol ActiveSessionDIContainer {
    func friendListRepository() -> FriendsRepository
    func authorizedSessionRepository() -> UsersRepository
    func friendInterationsUseCase() -> FriendInteractionsUseCase
    func qrInviteUseCase() -> QRInviteUseCase
}
