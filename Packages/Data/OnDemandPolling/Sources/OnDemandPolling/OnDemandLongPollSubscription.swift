import AsyncExtensions
import Api
import Logging

public actor OnDemandLongPollSubscription<T: Sendable, Q: LongPollQuery> {
    public let logger: Logger
    private let taskFactory: TaskFactory
    private let subscribersCount: SubscribersCount<T>
    private let longPollPublisher: any AsyncBroadcast<Q.Update>

    private var subsctiptionsCountSubscription: (any CancellableEventSource)?
    private var longPollSubscription: (any CancellableEventSource)?

    public init(
        subscribersCount: SubscribersCount<T>,
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q,
        logger: Logger
    ) async where Q.Update: Decodable {
        self.logger = logger.with(prefix: "🕰️")
        self.subscribersCount = subscribersCount
        longPollPublisher = await longPoll.poll(for: query)
        self.taskFactory = taskFactory
    }

    public func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        logI { "start polling" }
        subsctiptionsCountSubscription = await subscribersCount.countPublisher
            .subscribe { [weak self, taskFactory] subscriptionsCount in
                guard let self else { return }
                logI { "subscriptions count updated: \(subscriptionsCount)" }
                taskFactory.task { [weak self] in
                    guard let self else { return }
                    await subscriptionsCountUpdated(subscriptionsCount, onLongPoll: onLongPoll)
                }
            }
    }

    private func subscriptionsCountUpdated(
        _ subscriptionsCount: Int,
        onLongPoll: @escaping @Sendable (Q.Update) -> Void
    ) async {
        logI { "subscriptions count updated: \(subscriptionsCount)" }
        let hadSubsriptions = longPollSubscription != nil
        let hasSubscriptions: Bool
        if hadSubsriptions {
            let isSubscribedToSamePublisher = longPollPublisher.id == subscribersCount.ownerPublisher.id
            hasSubscriptions = subscriptionsCount - (isSubscribedToSamePublisher ? 1 : 0) > 0
        } else {
            hasSubscriptions = subscriptionsCount > 0
        }
        guard hadSubsriptions != hasSubscriptions else {
            logI { "nothing to update" }
            return
        }
        logI { "updating onDemandPublishing: \(hasSubscriptions ? "has subscriptions" : "has no subscriptions")" }
        await longPollSubscription?.cancel()
        if hasSubscriptions {
            longPollSubscription = await longPollPublisher.subscribe { update in
                onLongPoll(update)
            }
        } else {
            longPollSubscription = nil
        }
    }
}

extension OnDemandLongPollSubscription: Loggable {}
