import Foundation
import ApiService
internal import Base

class MaxSimultaneousRequestsRestrictor {
    private let manager: ApiServiceRequestRunnersManager
    private let queue = DispatchQueue(label: "\(MaxSimultaneousRequestsRestrictor.self)")
    private let semaphore: DispatchSemaphore

    init(limit: Int, manager: ApiServiceRequestRunnersManager) {
        semaphore = DispatchSemaphore(value: limit)
        self.manager = manager
    }

    func run<Request: ApiServiceRequest, Response: Decodable>(
        request: Request
    ) async throws(ApiServiceError) -> Response {
        let result: Result<Response, ApiServiceError> = await withCheckedContinuation { continuation in
            self.queue.async {
                self.runImpl(request: request) { result in
                    continuation.resume(returning: result)
                }
            }
        }
        return try result.get()
    }

    func runImpl<Request: ApiServiceRequest, Response: Decodable>(
        request: Request,
        completion: @escaping (Result<Response, ApiServiceError>) -> Void
    ) {
        semaphore.wait()
        manager.run(request: request) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async(execute: curry(completion)(result))
            semaphore.signal()
        }
    }
}
