import Api

public protocol ServerSideEventsServiceFactory: Sendable {
    func create(
        refreshTokenMiddleware: AuthMiddleware?
    ) -> RemoteUpdatesService
}
