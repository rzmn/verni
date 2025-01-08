public struct UsersOperations: Sendable, Equatable {
    public let running: [UsersOperation]
    public let failed: [UsersOperation]
    public let succeeded: [UsersOperation]
}
