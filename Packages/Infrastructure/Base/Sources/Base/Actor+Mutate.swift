public extension Actor {
    func mutate(_ block: @Sendable (isolated Self) -> Void) {
        block(self)
    }
}
