public protocol NetworkService {
    func run<T: NetworkRequest>(
        _ request: T
    ) async throws(NetworkServiceError) -> NetworkServiceResponse
}
