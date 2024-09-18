import AsyncExtensions

public protocol LongPoll: Sendable {
    func poll<Query: LongPollQuery>(for query: Query) async -> any AsyncBroadcast<Query.Update>
}
