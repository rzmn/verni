import Api
import Base
import AsyncExtensions
import Logging

public actor DefaultLongPoll: LongPoll {
    private var notifiers = [String: Any]()
    private let api: DefaultApi
    private let taskFactory: TaskFactory
    private let logger: Logger

    init(api: DefaultApi, taskFactory: TaskFactory, logger: Logger) {
        self.api = api
        self.taskFactory = taskFactory
        self.logger = logger
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
        let notifier = await LongPollUpdateNotifier(query: query, api: api, taskFactory: taskFactory, logger: logger)
        notifiers[query.eventId] = notifier
        return notifier
    }
}
