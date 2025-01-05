import Foundation

public protocol ApiService: Sendable {
    func run(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Data
}
