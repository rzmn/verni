import Testing
import DataTransferObjects
import Domain
import Foundation
import Base
@testable import AsyncExtensions
@testable import Api
@testable import DefaultSpendingsRepositoryImplementation
@testable import MockApiImplementation

private struct MockLongPoll: LongPoll {
    let getCounterpartiesBroadcast: AsyncSubject<LongPollCounterpartiesQuery.Update>
    let getSpendingsHistoryBroadcast: AsyncSubject<LongPollSpendingsHistoryQuery.Update>

    func poll<Query: LongPollQuery>(for query: Query) async -> any AsyncBroadcast<Query.Update> {
        if Query.self == LongPollCounterpartiesQuery.self {
            return getCounterpartiesBroadcast as! any AsyncBroadcast<Query.Update>
        } else if Query.self == LongPollSpendingsHistoryQuery.self {
            return getSpendingsHistoryBroadcast as! any AsyncBroadcast<Query.Update>
        } else {
            fatalError()
        }
    }
}

private actor ApiProvider {
    let api: MockApi
    let mockLongPoll: MockLongPoll

    var getCounterpartiesCalledCount = 0
    private let getCounterpartiesResponse: [BalanceDto]

    var getSpendingsHistoryCalls: [UserDto.Identifier] = []
    private let getSpendingsHistoryResponse: [UserDto.Identifier: [IdentifiableExpenseDto]]

    var getDealCalls: [ExpenseDto.Identifier] = []
    private let getDealResponse: [ExpenseDto.Identifier: ExpenseDto]

    init(
        getCounterpartiesResponse: [BalanceDto] = [],
        getSpendingsHistoryResponse: [UserDto.Identifier: [IdentifiableExpenseDto]] = [:],
        getDealResponse: [ExpenseDto.Identifier: ExpenseDto] = [:],
        taskFactory: TaskFactory
    ) async {
        self.getCounterpartiesResponse = getCounterpartiesResponse
        self.getSpendingsHistoryResponse = getSpendingsHistoryResponse
        self.getDealResponse = getDealResponse
        api = MockApi()
        mockLongPoll = MockLongPoll(
            getCounterpartiesBroadcast: AsyncSubject(
                taskFactory: taskFactory
            ),
            getSpendingsHistoryBroadcast: AsyncSubject(
                taskFactory: taskFactory
            )
        )
        await api.performIsolated { api in
            api.runMethodWithoutParamsBlock = { method in
                await self.performIsolated { `self` in
                    if let _ = method as? Spendings.GetBalance {
                        self.getCounterpartiesCalledCount += 1
                    }
                }
                return self.getCounterpartiesResponse
            }
            api.runMethodWithParamsBlock = { method in
                await self.performIsolated { `self` in
                    if let method = method as? Spendings.GetDeals {
                        self.getSpendingsHistoryCalls.append(method.parameters.counterparty)
                    } else if let method = method as? Spendings.GetDeal {
                        self.getDealCalls.append(method.parameters.dealId)
                    }
                }
                if let method = method as? Spendings.GetDeals {
                    return self.getSpendingsHistoryResponse[method.parameters.counterparty]
                } else if let method = method as? Spendings.GetDeal {
                    return self.getDealResponse[method.parameters.dealId]
                } else {
                    fatalError()
                }
            }
        }
    }
}

private actor MockOfflineMutableRepository: SpendingsOfflineMutableRepository {
    var spendingCounterpariesUpdates: [ [SpendingsPreview] ] = []
    var spendingHisoryUpdatesById: [User.Identifier: [[IdentifiableSpending]]] = [:]

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        spendingCounterpariesUpdates.append(counterparties)
    }

    func updateSpendingsHistory(counterparty: User.Identifier, history: [IdentifiableSpending]) async {
        let updates = spendingHisoryUpdatesById[counterparty, default: []] + [history]
        spendingHisoryUpdatesById[counterparty] = updates
    }
}

@Suite(.timeLimit(.minutes(1))) struct SpendingsRepositoryTests {

    @Test func testRefreshCounterparties() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let counterparties = [
            SpendingsPreview(
                counterparty: UUID().uuidString,
                balance: [
                    .russianRuble: 19
                ]
            )
        ]
        let apiProvider = await ApiProvider(
            getCounterpartiesResponse: counterparties.map(BalanceDto.init),
            taskFactory: taskFactory
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        try await confirmation { confirmation in
            let cancellableStream = await repository.spendingCounterpartiesUpdated().subscribeWithStream()
            let stream = await cancellableStream.eventSource.stream
            let counterpartiesFromRepository = try await repository.refreshSpendingCounterparties()
            taskFactory.task {
                for await counterpartiesFromPublisher in stream {
                    #expect(counterparties == counterpartiesFromPublisher)
                    confirmation()
                }
            }
            #expect(counterpartiesFromRepository == counterparties)
            await cancellableStream.cancel()
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await apiProvider.getCounterpartiesCalledCount == 1)
        #expect(await offlineRepository.spendingCounterpariesUpdates == [counterparties])
    }

    @Test func testSpendingCounterpartiesPolling() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let counterparties = [
            SpendingsPreview(
                counterparty: UUID().uuidString,
                balance: [
                    .russianRuble: 19
                ]
            )
        ]
        let apiProvider = await ApiProvider(
            getCounterpartiesResponse: counterparties.map(BalanceDto.init),
            taskFactory: taskFactory
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        try await confirmation { confirmation in
            let subscription = await repository.spendingCounterpartiesUpdated().subscribe { counterpartiesFromPublisher in
                #expect(counterparties == counterpartiesFromPublisher)
                confirmation()
            }
            try await taskFactory.runUntilIdle()
            await apiProvider.mockLongPoll.getCounterpartiesBroadcast.yield(
                LongPollCounterpartiesQuery.Update(category: .counterparties)
            )
            try await taskFactory.runUntilIdle()
            await subscription.cancel()
        }

        // then

        #expect(await apiProvider.getCounterpartiesCalledCount == 1)
        #expect(await offlineRepository.spendingCounterpariesUpdates == [counterparties])
    }

    @Test func testRefreshSpendingsHistory() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let counterparty = UUID().uuidString
        let history = [
            IdentifiableSpending(
                spending: Spending(
                    date: Date(),
                    details: "dlts",
                    cost: 15,
                    currency: .euro,
                    participants: [
                        UUID().uuidString: 44
                    ]
                ),
                id: UUID().uuidString
            )
        ]
        let apiProvider = await ApiProvider(
            getSpendingsHistoryResponse: [counterparty: history.map(IdentifiableExpenseDto.init)],
            taskFactory: taskFactory
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        try await confirmation { confirmation in
            let cancellableStream = await repository.spendingsHistoryUpdated(for: counterparty).subscribeWithStream()
            let stream = await cancellableStream.eventSource.stream
            let historyFromRepository = try await repository.refreshSpendingsHistory(counterparty: counterparty)
            taskFactory.task {
                for await spendingsHistoryFromPublisher in stream {
                    #expect(history == spendingsHistoryFromPublisher)
                    confirmation()
                }
            }
            #expect(historyFromRepository == history)
            await cancellableStream.cancel()
            try await taskFactory.runUntilIdle()
        }

        // then

        #expect(await apiProvider.getSpendingsHistoryCalls == [counterparty])
        #expect(await offlineRepository.spendingHisoryUpdatesById[counterparty] == [history])
    }

    @Test func testSpendingsHistoryPolling() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let counterparty = UUID().uuidString
        let history = [
            IdentifiableSpending(
                spending: Spending(
                    date: Date(),
                    details: "dlts",
                    cost: 15,
                    currency: .euro,
                    participants: [
                        UUID().uuidString: 44
                    ]
                ),
                id: UUID().uuidString
            )
        ]
        let apiProvider = await ApiProvider(
            getSpendingsHistoryResponse: [counterparty: history.map(IdentifiableExpenseDto.init)],
            taskFactory: taskFactory
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        try await confirmation { confirmation in
            let subscription = await repository.spendingsHistoryUpdated(for: counterparty).subscribe { spendingsHistoryFromPublisher in
                #expect(history == spendingsHistoryFromPublisher)
                confirmation()
            }
            try await taskFactory.runUntilIdle()
            await apiProvider.mockLongPoll.getSpendingsHistoryBroadcast.yield(
                LongPollSpendingsHistoryQuery.Update(
                    category: .spendings(uid: counterparty)
                )
            )
            try await taskFactory.runUntilIdle()
            await subscription.cancel()
        }

        // then

        #expect(await apiProvider.getSpendingsHistoryCalls == [counterparty])
        #expect(await offlineRepository.spendingHisoryUpdatesById[counterparty] == [history])
    }

    @Test func testGetDeal() async throws {

        // given

        let taskFactory = TestTaskFactory()
        let deal = IdentifiableSpending(
            spending: Spending(
                date: Date(),
                details: "dlts",
                cost: 15,
                currency: .euro,
                participants: [
                    UUID().uuidString: 44
                ]
            ),
            id: UUID().uuidString
        )
        let apiProvider = await ApiProvider(
            getDealResponse: [deal.id: ExpenseDto(domain: deal.spending)],
            taskFactory: taskFactory
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = await DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let dealFromRepository = try await repository.getSpending(id: deal.id)
        try await taskFactory.runUntilIdle()

        // then

        #expect(dealFromRepository == deal.spending)
        #expect(await apiProvider.getDealCalls == [deal.id])
    }
}
