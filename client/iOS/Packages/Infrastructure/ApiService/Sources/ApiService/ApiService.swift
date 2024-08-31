public protocol ApiService {
    func run<Request: ApiServiceRequest, Response: Decodable>(
        request: Request
    ) async throws(ApiServiceError) -> Response
}
