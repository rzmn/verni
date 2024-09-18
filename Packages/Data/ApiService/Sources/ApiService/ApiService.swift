public protocol ApiService: Sendable {
    func run<Response: Decodable & Sendable>(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Response
}
