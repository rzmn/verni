public extension Sequence where Element: Sendable {
    func asyncMap<T: Sendable>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func concurrentMap<T: Sendable>(
        taskFactory: TaskFactory,
        _ transform: @escaping @Sendable (Element) async -> T
    ) async -> [T] {
        let tasks = map { element in
            taskFactory.task {
                await transform(element)
            }
        }

        return await tasks.asyncMap { task in
            await task.value
        }
    }
}
