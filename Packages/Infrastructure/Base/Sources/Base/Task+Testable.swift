import Foundation

protocol Waitable {
    @discardableResult
    func wait() async throws -> Any
}

extension Task: Waitable {
    func wait() async throws -> Any {
        try await value
    }
}

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

final class TestTaskFactory: TaskFactory, @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [Waitable] = []

    func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        lock.lock()
        defer {
            lock.unlock()
        }
        let task = Task(priority: priority) {
            try await operation()
        }
        tasks.append(task)
        return task
    }

    public func task<Success>(
        priority: TaskPriority?,
        @_inheritActorContext operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        lock.lock()
        defer {
            lock.unlock()
        }
        let task = Task(priority: priority) {
            await operation()
        }
        tasks.append(task)
        return task
    }

    func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task<Success, Error> {
        lock.lock()
        defer {
            lock.unlock()
        }
        let task = Task.detached(priority: priority) {
            try await operation()
        }
        tasks.append(task)
        return task
    }

    public func detached<Success>(
        priority: TaskPriority?,
        operation: @Sendable @escaping () async -> Success
    ) -> Task<Success, Never> {
        lock.lock()
        defer {
            lock.unlock()
        }
        let task = Task.detached(priority: priority) {
            await operation()
        }
        tasks.append(task)
        return task
    }

    func runUntilIdle() async throws {
        var firstTask: Waitable? {
            lock.lock()
            defer {
                lock.unlock()
            }
            return tasks.first
        }
        func removeFirst() {
            lock.lock()
            defer {
                lock.unlock()
            }
            tasks.removeFirst()
        }
        while let task = firstTask {
            try await task.wait()
            removeFirst()
        }
    }
}
