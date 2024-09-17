import AsyncExtensions

public protocol LongPoll: Sendable {
    func poll<Query>(for query: Query) async -> any AsyncBroadcast<Query.Update>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable
}
