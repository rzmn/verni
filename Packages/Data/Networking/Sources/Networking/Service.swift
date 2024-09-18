public protocol NetworkService: Sendable {
    func run(_ request: some NetworkRequest) async throws(NetworkServiceError) -> NetworkServiceResponse
}
