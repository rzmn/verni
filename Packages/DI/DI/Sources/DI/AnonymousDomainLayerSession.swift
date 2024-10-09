import Domain

public protocol AnonymousDomainLayerSession: AppCommonCovertible, Sendable {
    func authUseCase() -> any AuthUseCase<AuthenticatedDomainLayerSession>
}
