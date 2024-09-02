public protocol NetworkServiceFactory: Sendable {
    func create() -> NetworkService
}
