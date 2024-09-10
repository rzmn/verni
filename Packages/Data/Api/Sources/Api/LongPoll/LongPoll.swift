import Combine

public protocol LongPoll: Sendable {
    func poll<Query>(for query: Query) async -> AnyPublisher<Query.Update, Never>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable
}
