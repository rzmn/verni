public protocol AuthMiddleware: Sendable {
    func intercept<E: AuthMiddlewareError>(
        routine: @escaping @Sendable (_ authHeaderValue: String?) async -> Result<Void, E>
    ) async throws
}
