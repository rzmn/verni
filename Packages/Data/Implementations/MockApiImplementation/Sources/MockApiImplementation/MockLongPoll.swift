import Api
import AsyncExtensions

actor MockLongPoll: LongPoll {
    var _impl: LongPoll?

    func poll<Query>(for query: Query) async -> any AsyncPublisher<Query.Update>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable {
        await _impl!.poll(for: query)
    }
}
