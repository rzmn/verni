import Domain

public protocol AuthUseCaseReturningActiveSession: AuthUseCase
where Self.AuthorizedSession == ActiveSessionDIContainer {}

public protocol DIContainer: AppCommonCovertible, Sendable {
    func authUseCase() -> any AuthUseCaseReturningActiveSession
}
