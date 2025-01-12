import Foundation
import AsyncExtensions

public struct DefaultTaskFactory: TaskFactory {
    public init() {}

    public func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        Task(priority: priority) {
            try await operation()
        }
    }

    public func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        Task(priority: priority) {
            await operation()
        }
    }

    @discardableResult
    public func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        Task.detached(priority: priority) {
            try await operation()
        }
    }

    @discardableResult
    public func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        Task.detached(priority: priority) {
            await operation()
        }
    }
}
