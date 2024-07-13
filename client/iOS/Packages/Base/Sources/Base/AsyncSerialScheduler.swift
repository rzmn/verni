public actor AsyncSerialScheduler {
    private var previousTask: Task<Void, Error>?

    public init() {}

    public func run(_ block: @Sendable @escaping () async throws -> Void) {
        previousTask = Task { [previousTask] in
            let _ = await previousTask?.result
            return try await block()
        }
    }
}
