import Combine
import Api
internal import Base

public actor DefaultLongPoll: LongPoll {
    private var notifiers = [String: Any]()
    private let api: DefaultApi

    init(api: DefaultApi) {
        self.api = api
    }

    public func poll<Query>(
        for query: Query
    ) async -> AnyPublisher<Query.Update, Never>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable {
        await updateNotifier(for: query).publisher
    }

    func updateNotifier<Query>(
        for query: Query
    ) async -> LongPollUpdateNotifier<Query>
    where Query: LongPollQuery, Query.Update: Decodable & Sendable {
        let existed: LongPollUpdateNotifier<Query>?
        if let anyExisted = notifiers[query.eventId] {
            if let existedCasted = anyExisted as? LongPollUpdateNotifier<Query> {
                existed = existedCasted
            } else {
                assertionFailure()
                existed = nil
            }
        } else {
            existed = nil
        }
        if let existed {
            return existed
        }
        let notifier = await LongPollUpdateNotifier(query: query, api: api)
        notifiers[query.eventId] = notifier
        return notifier
    }
}
