import Api
import Base
import AsyncExtensions

public actor DefaultLongPoll: LongPoll {
    private var notifiers = [String: Any]()
    private let api: DefaultApi
    private let taskFactory: TaskFactory

    init(api: DefaultApi, taskFactory: TaskFactory) {
        self.api = api
        self.taskFactory = taskFactory
    }

    public func poll<Query: LongPollQuery>(
        for query: Query
    ) async -> any AsyncBroadcast<Query.Update> {
        await updateNotifier(for: query).publisher
    }

    func updateNotifier<Query: LongPollQuery>(
        for query: Query
    ) async -> LongPollUpdateNotifier<Query> {
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
        let notifier = await LongPollUpdateNotifier(query: query, api: api, taskFactory: taskFactory)
        notifiers[query.eventId] = notifier
        return notifier
    }
}
