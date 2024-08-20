import Combine
import Api
internal import Base

public actor DefaultLongPoll: LongPoll {
    private var notifiers = [String: Any]()

    public func create<Query: LongPollQuery>(
        for query: Query
    ) async -> AnyPublisher<Query.Update, Never> {
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
            return await existed.publisher
        }
        let notifier = LongPollUpdateNotifier(query: query)
        notifiers[query.eventId] = notifier
        return await notifier.publisher
    }
}
