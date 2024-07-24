import Networking

public protocol ApiService {
    func run<Request: NetworkRequest, Response: Decodable>(
        request: Request
    ) async -> Result<Response, ApiServiceError>
}
