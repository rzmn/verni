public protocol ApiService: Sendable {
    func run<Request: ApiServiceRequest, Response: Decodable & Sendable>(
        request: Request
    ) async throws(ApiServiceError) -> Response
}
