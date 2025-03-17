public protocol AuthMiddlewareError: Sendable {
    var isTokenExpired: Bool { get }
}
