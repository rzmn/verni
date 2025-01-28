import Foundation
import AsyncExtensions

protocol Waitable {
    @discardableResult
    func wait() async throws -> Any
}

extension Task: Waitable {
    func wait() async throws -> Any {
        try await value
    }
}

// swiftlint:disable:next no_unchecked_sendable
public final class TestTaskFactory: TaskFactory, @unchecked Sendable {
    private let lock = NSLock()
    private var tasks: [Waitable] = []

    public init() {}

    public func task<Success>(
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

    public func detached<Success>(
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

    public func runUntilIdle() async throws {
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
