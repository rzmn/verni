import Networking

actor MockRequestService: NetworkService {
    let result: Result<NetworkServiceResponse, NetworkServiceError>

    init(result: Result<NetworkServiceResponse, NetworkServiceError>) {
        self.result = result
    }

    func run<T: NetworkRequest>(_ request: T) async throws(NetworkServiceError) -> NetworkServiceResponse {
        try result.get()
    }
}
