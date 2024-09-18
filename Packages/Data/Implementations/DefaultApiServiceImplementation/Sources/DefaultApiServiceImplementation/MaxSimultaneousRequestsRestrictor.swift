import Foundation
import ApiService
import Base
import AsyncExtensions

actor MaxSimultaneousRequestsRestrictor {
    private let manager: ApiServiceRequestRunnersManager

    private let simultaneouslyRunningTasksLimit: Int
    private let taskFactory: TaskFactory
    private var currentRunningTasksCount: Int
    private var hasFreeSlotContinuation: CheckedContinuation<Void, Never>?
    private var hasFreeSlotTask: Task<Void, Never>?

    init(
        limit: Int,
        manager: ApiServiceRequestRunnersManager,
        taskFactory: TaskFactory
    ) {
        simultaneouslyRunningTasksLimit = limit
        currentRunningTasksCount = 0
        self.taskFactory = taskFactory
        self.manager = manager
    }

    func run<Response: Decodable & Sendable>(
        request: some ApiServiceRequest
    ) async throws(ApiServiceError) -> Response {
        await ensureLimit()
        let result: Result<Response, ApiServiceError>
        do {
            result = .success(try await manager.run(request: request))
        } catch {
            result = .failure(error)
        }
        taskFinished()
        return try result.get()
    }
}

// MARK: - Private

extension MaxSimultaneousRequestsRestrictor {
    func ensureLimit() async {
        if let hasFreeSlotTask {
            await hasFreeSlotTask.value
            self.hasFreeSlotTask = nil
            self.hasFreeSlotContinuation = nil
        }
        currentRunningTasksCount += 1
        if currentRunningTasksCount == simultaneouslyRunningTasksLimit {
            hasFreeSlotTask = taskFactory.task {
                await withCheckedContinuation { continuation in
                    self.hasFreeSlotContinuation = continuation
                }
            }
        }
    }

    func taskFinished() {
        let shouldResumeContinuation = currentRunningTasksCount == simultaneouslyRunningTasksLimit
        currentRunningTasksCount -= 1
        if let hasFreeSlotContinuation, shouldResumeContinuation {
            hasFreeSlotContinuation.resume()
        }
    }
}
