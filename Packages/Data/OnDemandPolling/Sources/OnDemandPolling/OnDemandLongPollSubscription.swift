import AsyncExtensions
import Api
import Logging

public actor OnDemandLongPollSubscription<T: Sendable, Q: LongPollQuery> {
    public let logger: Logger
    private let taskFactory: TaskFactory
    private let subscribersCount: SubscribersCount<T>
    private let longPollPublisher: any AsyncPublisher<Q.Update>

    private var subsctiptionsCountSubscription: (any CancellableEventSource)?
    private var longPollSubscription: (any CancellableEventSource)?

    public init(
        subscribersCount: SubscribersCount<T>,
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q,
        logger: Logger = .shared
    ) async where Q.Update: Decodable {
        self.logger = logger.with(prefix: "\(Q.self)")
        self.subscribersCount = subscribersCount
        longPollPublisher = await longPoll.poll(for: query)
        self.taskFactory = taskFactory
    }

    public func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        logI { "start polling" }
        subsctiptionsCountSubscription = await subscribersCount.countPublisher.subscribe { [weak self, taskFactory] subscriptionsCount in
            self?.logI { "subscriptions count updated: \(subscriptionsCount)" }
            taskFactory.task { [weak self] in
                await self?.mutate { s in
                    let hadSubsriptions = s.longPollSubscription != nil
                    let hasSubscriptions: Bool
                    if hadSubsriptions {
                        let isSubscribedToSamePublisher = s.longPollPublisher.id == s.subscribersCount.ownerPublisher.id
                        hasSubscriptions = subscriptionsCount - (isSubscribedToSamePublisher ? 1 : 0) > 0
                    } else {
                        hasSubscriptions = subscriptionsCount > 0
                    }
                    guard hadSubsriptions != hasSubscriptions else {
                        s.logI { "nothing to update" }
                        return
                    }
                    s.logI { "updating onDemandPublishing: \(hasSubscriptions ? "has subscriptions" : "has no subscriptions")" }
                    await s.longPollSubscription?.cancel()
                    if hasSubscriptions {
                        s.longPollSubscription = await s.longPollPublisher.subscribe { update in
                            onLongPoll(update)
                        }
                    } else {
                        s.longPollSubscription = nil
                    }
                }
            }
        }
    }
}

extension OnDemandLongPollSubscription: Loggable {}
