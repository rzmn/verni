import Api
import Combine

actor MockLongPoll: LongPoll {
    var _poll: (@Sendable (any LongPollQuery) async -> AnyPublisher<any Decodable & Sendable, Never>)?

    func poll<Query>(for query: Query) async -> AnyPublisher<Query.Update, Never>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable {
        await _poll!(query)
            .map {
                $0 as! Query.Update
            }
            .eraseToAnyPublisher()
    }
}
