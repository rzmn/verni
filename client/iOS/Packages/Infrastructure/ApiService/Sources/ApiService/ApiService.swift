public protocol ApiService {
    func run<Request: ApiServiceRequest, Response: Decodable>(
        request: Request
    ) async -> Result<Response, ApiServiceError>
}
