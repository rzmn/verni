import Foundation

public protocol TaskFactory: Sendable {
    @discardableResult
    func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error>

    @discardableResult
    func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never>

    @discardableResult
    func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error>

    @discardableResult
    func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never>
}

public extension TaskFactory {
    @discardableResult
    func task<Success>(
        @_inheritActorContext operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        task(priority: nil, operation: operation)
    }

    @discardableResult
    func task<Success>(
        @_inheritActorContext operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        task(priority: nil, operation: operation)
    }

    @discardableResult
    func detached<Success>(
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        detached(priority: nil, operation: operation)
    }

    @discardableResult
    func detached<Success>(
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        detached(priority: nil, operation: operation)
    }
}
