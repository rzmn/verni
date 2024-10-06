public protocol ApiServiceFactory: Sendable {
    func create(tokenRefresher: TokenRefresher?) -> ApiService
}
