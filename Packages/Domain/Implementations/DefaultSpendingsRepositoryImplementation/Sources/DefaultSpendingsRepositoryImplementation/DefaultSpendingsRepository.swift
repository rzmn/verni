import Domain
import Api
import PersistentStorage
import Logging
import Base
import AsyncExtensions
import OnDemandPolling
internal import ApiDomainConvenience

private struct OnDemandLongPollBroadcast<T: Sendable, Q: LongPollQuery> {
    let broadcast: AsyncSubject<T>
    private let subscription: OnDemandLongPollSubscription<T, Q>
    init(
        longPoll: LongPoll,
        taskFactory: TaskFactory,
        query: Q,
        logger: Logger = .shared
    ) async where Q.Update: Decodable {
        broadcast = AsyncSubject(
            taskFactory: taskFactory
        )
        subscription = await OnDemandLongPollSubscription(
            subscribersCount: broadcast.subscribersCount,
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: query,
            logger: logger
        )
    }

    func start(onLongPoll: @escaping @Sendable (Q.Update) -> Void) async {
        await subscription.start(onLongPoll: onLongPoll)
    }
}
private typealias CounterpartiesBroadcast = OnDemandLongPollBroadcast<
    [SpendingsPreview],
    LongPollCounterpartiesQuery
>
private typealias SpendingsHistoryBroadcast = OnDemandLongPollBroadcast<
    [IdentifiableSpending],
    LongPollSpendingsHistoryQuery
>
public actor DefaultSpendingsRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let longPoll: LongPoll
    private let offline: SpendingsOfflineMutableRepository
    private let taskFactory: TaskFactory

    private let onDemandCounterpartiesSubscription: CounterpartiesBroadcast
    private var onDemandSpendingHistorySubscriptionById = [User.Identifier: SpendingsHistoryBroadcast]()

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
        self.onDemandCounterpartiesSubscription = await OnDemandLongPollBroadcast(
            longPoll: longPoll,
            taskFactory: taskFactory,
            query: LongPollCounterpartiesQuery()
        )
        await onDemandCounterpartiesSubscription.start { [weak self] _ in
            guard let self else { return }
            self.taskFactory.task {
                try? await self.refreshSpendingCounterparties()
            }
        }
    }
}

extension DefaultSpendingsRepository: SpendingsRepository {
    public func getSpending(id: Spending.Identifier) async throws(GetSpendingError) -> Spending {
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
        with uid: User.Identifier
    ) async -> OnDemandLongPollBroadcast<[IdentifiableSpending], LongPollSpendingsHistoryQuery> {
        guard let subject = onDemandSpendingHistorySubscriptionById[uid] else {
            logI { "subject created for \(uid)" }
            let subject = await OnDemandLongPollBroadcast<[IdentifiableSpending], LongPollSpendingsHistoryQuery>(
                longPoll: longPoll,
                taskFactory: taskFactory,
                query: LongPollSpendingsHistoryQuery(uid: uid)
            )
            await subject.start { _ in
                self.taskFactory.task {
                    try? await self.refreshSpendingsHistory(counterparty: uid)
                }
            }
            onDemandSpendingHistorySubscriptionById[uid] = subject
            return subject
        }
        return subject
    }

    public func spendingCounterpartiesUpdated() async -> any AsyncBroadcast<[SpendingsPreview]> {
        onDemandCounterpartiesSubscription.broadcast
    }

    public func spendingsHistoryUpdated(for id: User.Identifier) async -> any AsyncBroadcast<[IdentifiableSpending]> {
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

    public func refreshSpendingsHistory(
        counterparty: User.Identifier
    ) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending] {
        logI { "refreshSpendingsHistory[counterparty=\(counterparty)] start" }
        let spendings: [IdentifiableSpending]
        do {
            spendings = try await api.run(
                method: Spendings.GetDeals(
                    counterparty: counterparty
                )
            ).map(IdentifiableSpending.init)
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
