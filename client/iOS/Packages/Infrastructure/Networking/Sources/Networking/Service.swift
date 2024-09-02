public protocol NetworkService: Sendable {
    func run<T: NetworkRequest>(
        _ request: T
    ) async throws(NetworkServiceError) -> NetworkServiceResponse
}
