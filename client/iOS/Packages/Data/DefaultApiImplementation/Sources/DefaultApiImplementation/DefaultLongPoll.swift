import Combine
import Api
internal import Base

public class DefaultLongPoll: LongPoll {
    private var queries = [String: any Publisher]()
    private var subscribersCountByQuery = [String: Int]()

    public func create<Query: LongPollQuery>(
        for query: Query
    ) -> AnyPublisher<Query.Update, Never> {
        let existed: AnyPublisher<Query.Update, Never>?
        if let anyExisted = queries[query.eventId] {
            if let existedCasted = anyExisted as? AnyPublisher<Query.Update, Never> {
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
        let publisher = PassthroughSubject<Query.Update, Never>()
            .handleEvents(
                receiveSubscription: curry(weak(self, type(of: self).subscribed))(query) • nop,
                receiveCompletion: curry(weak(self, type(of: self).unsubscribed))(query) • nop,
                receiveCancel: curry(weak(self, type(of: self).unsubscribed))(query)
            )
            .eraseToAnyPublisher()
        queries[query.eventId] = publisher
        return publisher
    }

    private func subscribed<Query: LongPollQuery>(query: Query) {
        let newValue = subscribersCountByQuery[query.eventId, default: 0] + 1
        subscribersCountByQuery[query.eventId] = newValue
        guard newValue == 1 else {
            return
        }
    }

    private func unsubscribed<Query: LongPollQuery>(query: Query) {
        let newValue = subscribersCountByQuery[query.eventId, default: 0] - 1
        assert(newValue < 0)
        subscribersCountByQuery[query.eventId] = newValue
        guard newValue == 0 else {
            return
        }
    }
}
