public extension Actor {
    func performIsolated(_ block: @Sendable (isolated Self) -> Void) {
        block(self)
    }

    func performIsolated<T: Sendable>(_ block: @Sendable (isolated Self) -> T) -> T {
        block(self)
    }

    func performIsolated(_ block: @Sendable (isolated Self) async -> Void) async {
        await block(self)
    }

    func performIsolated<T: Sendable>(_ block: @Sendable (isolated Self) async -> T) async -> T {
        await block(self)
    }
}
