public extension Actor {
    func mutate(_ block: @Sendable (isolated Self) -> Void) {
        block(self)
    }

    func mutate(_ block: @Sendable (isolated Self) async -> Void) async {
        await block(self)
    }

    func mutate<T: Sendable>(_ block: @Sendable (isolated Self) async -> T) async -> T {
        await block(self)
    }
}
