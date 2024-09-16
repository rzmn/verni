import Domain
import Api
import PersistentStorage
import Logging
import Base
import AsyncExtensions
import OnDemandPolling
internal import ApiDomainConvenience

private struct BroadcastWithOnDemandLongPoll<T: Sendable, Q: LongPollQuery> {
    let broadcast: AsyncBroadcast<T>
    private let subscription: OnDemandLongPollSubscription<Q>
    init(
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q
    ) async where Q.Update: Decodable {
        let subscribersCountBroadcast: AsyncBroadcast<Int> = AsyncBroadcast(taskFactory: taskFactory)
        broadcast = AsyncBroadcast(
            taskFactory: taskFactory,
            subscribersCountTracking: subscribersCountBroadcast
        )
        subscription = await OnDemandLongPollSubscription(
            subscribersCountPublisher: subscribersCountBroadcast,
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: query
        )
    }

    func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        await subscription.start(onLongPoll: onLongPoll)
    }
}

public actor DefaultSpendingsRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let longPoll: LongPoll
    private let offline: SpendingsOfflineMutableRepository
    private let taskFactory: TaskFactory

    private let onDemandCounterpartiesSubscription: BroadcastWithOnDemandLongPoll<[SpendingsPreview], LongPollCounterpartiesQuery>
    private var onDemandSpendingHistorySubscriptionById = [User.ID: BroadcastWithOnDemandLongPoll<[IdentifiableSpending], LongPollSpendingsHistoryQuery>]()

    public init(
        api: ApiProtocol,
        longPoll: LongPoll,
        logger: Logger,
        offline: SpendingsOfflineMutableRepository,
        taskFactory: TaskFactory
    ) async {
        self.api = api
        self.longPoll = longPoll
        self.offline = offline
        self.logger = logger
        self.taskFactory = taskFactory
        self.onDemandCounterpartiesSubscription = await BroadcastWithOnDemandLongPoll(
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: LongPollCounterpartiesQuery()
        )
        await onDemandCounterpartiesSubscription.start { [weak self] update in
            guard let self else { return }
            self.taskFactory.task {
                try? await self.refreshSpendingCounterparties()
            }
        }
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpending(id: Spending.ID) async throws(GetSpendingError) -> Spending {
        logI { "getSpending[id=\(id)] start" }
        let result: Spending
        do {
            result = Spending(dto: try await api.run(method: Spendings.GetDeal(dealId: id)))
        } catch {
            logI { "getSpending[id=\(id)] failed error: \(error)" }
            throw GetSpendingError(apiError: error)
        }
        return result
    }

    private func spendingsHistorySubject(
        with uid: User.ID
    ) async -> BroadcastWithOnDemandLongPoll<[IdentifiableSpending], LongPollSpendingsHistoryQuery> {
        guard let subject = onDemandSpendingHistorySubscriptionById[uid] else {
            logI { "subject created for \(uid)" }
            let subject = await BroadcastWithOnDemandLongPoll<[IdentifiableSpending], LongPollSpendingsHistoryQuery>(
                longPoll: longPoll,
                taskFactory: taskFactory,
                query: LongPollSpendingsHistoryQuery(uid: uid)
            )
            await subject.start { update in
                self.taskFactory.task {
                    try? await self.refreshSpendingsHistory(counterparty: uid)
                }
            }
            onDemandSpendingHistorySubscriptionById[uid] = subject
            return subject
        }
        return subject
    }

    public func spendingCounterpartiesUpdated() async -> any AsyncPublisher<[SpendingsPreview]> {
        onDemandCounterpartiesSubscription.broadcast
    }

    public func spendingsHistoryUpdated(for id: User.ID) async -> any AsyncPublisher<[IdentifiableSpending]> {
        await spendingsHistorySubject(with: id).broadcast
    }

    public func refreshSpendingCounterparties() async throws(GeneralError) -> [SpendingsPreview] {
        logI { "refreshSpendingCounterparties start" }
        let counterparties: [SpendingsPreview]
        do {
            counterparties = try await api.run(method: Spendings.GetCounterparties()).map(SpendingsPreview.init)
        } catch {
            logI { "refreshSpendingCounterparties failed error: \(error)" }
            throw GeneralError(apiError: error)
        }
        taskFactory.detached {
            await self.offline.updateSpendingCounterparties(counterparties)
        }
        logI { "refreshSpendingCounterparties ok" }
        await onDemandCounterpartiesSubscription.broadcast.yield(counterparties)
        return counterparties
    }

    public func refreshSpendingsHistory(counterparty: User.ID) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending] {
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] start" }
        let spendings: [IdentifiableSpending]
        do {
            spendings = try await api.run(method: Spendings.GetDeals(counterparty: counterparty)).map(IdentifiableSpending.init)
        } catch {
            logI { "refreshSpendingsHistory[counterparty=\(counterparty)] failed error: \(error)" }
            throw GetSpendingsHistoryError(apiError: error)
        }
        taskFactory.detached {
            await self.offline.updateSpendingsHistory(counterparty: counterparty, history: spendings)
        }
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] ok" }
        await spendingsHistorySubject(with: counterparty).broadcast.yield(spendings)
        return spendings
    }
}

extension DefaultSpendingsRepository: Loggable {}
