import AsyncExtensions
import Api
import Logging

public actor OnDemandLongPollSubscription<T: Sendable> {
    public let logger: Logger
    private let taskFactory: TaskFactory
    private let subscribersCount: SubscribersCount<T>
    private let longPollPublisher: any AsyncBroadcast<RemoteUpdate>

    private var subsctiptionsCountSubscription: (any CancellableEventSource)?
    private var longPollSubscription: (any CancellableEventSource)?

    public init(
        subscribersCount: SubscribersCount<T>,
        service: RemoteUpdatesService,
        taskFactory: TaskFactory,
        logger: Logger
    ) async{
        self.logger = logger.with(prefix: "🕰️")
        self.subscribersCount = subscribersCount
        longPollPublisher = await service.subscribe()
        self.taskFactory = taskFactory
    }

    public func start(onUpdate: @escaping @Sendable (RemoteUpdate) -> Void) async {
        logI { "start polling" }
        subsctiptionsCountSubscription = await subscribersCount.countPublisher
            .subscribe { [weak self, taskFactory] subscriptionsCount in
                guard let self else { return }
                logI { "subscriptions count updated: \(subscriptionsCount)" }
                taskFactory.task { [weak self] in
                    guard let self else { return }
                    await subscriptionsCountUpdated(subscriptionsCount, onUpdate: onUpdate)
                }
            }
    }

    private func subscriptionsCountUpdated(
        _ subscriptionsCount: Int,
        onUpdate: @escaping @Sendable (RemoteUpdate) -> Void
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
                onUpdate(update)
            }
        } else {
            longPollSubscription = nil
        }
    }
}

extension OnDemandLongPollSubscription: Loggable {}
