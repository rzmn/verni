import Testing
import DataTransferObjects
import Domain
import Combine
import Foundation
@testable import Api
@testable import Base
@testable import DefaultSpendingsRepositoryImplementation
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    let mockLongPoll: MockLongPoll

    var getCounterpartiesCalledCount = 0
    let getCounterpartiesSubject = PassthroughSubject<LongPollCounterpartiesQuery.Update, Never>()
    private let getCounterpartiesResponse: [SpendingsPreviewDto]

    var getSpendingsHistoryCalls: [UserDto.ID] = []
    let getSpendingsHistorySubject = PassthroughSubject<LongPollSpendingsHistoryQuery.Update, Never>()
    private let getSpendingsHistoryResponse: [UserDto.ID: [IdentifiableDealDto]]

    var getDealCalls: [DealDto.ID] = []
    private let getDealResponse: [DealDto.ID: DealDto]

    init(
        getCounterpartiesResponse: [SpendingsPreviewDto] = [],
        getSpendingsHistoryResponse: [UserDto.ID: [IdentifiableDealDto]] = [:],
        getDealResponse: [DealDto.ID: DealDto] = [:]
    ) async {
        self.getCounterpartiesResponse = getCounterpartiesResponse
        self.getSpendingsHistoryResponse = getSpendingsHistoryResponse
        self.getDealResponse = getDealResponse
        api = MockApi()
        mockLongPoll = MockLongPoll()
        await api.mutate { api in
            api._runMethodWithoutParams = { method in
                await self.mutate { s in
                    if let _ = method as? Spendings.GetCounterparties {
                        s.getCounterpartiesCalledCount += 1
                    }
                }
                return self.getCounterpartiesResponse
            }
            api._runMethodWithParams = { method in
                await self.mutate { s in
                    if let method = method as? Spendings.GetDeals {
                        s.getSpendingsHistoryCalls.append(method.parameters.counterparty)
                    } else if let method = method as? Spendings.GetDeal {
                        s.getDealCalls.append(method.parameters.dealId)
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
        await mockLongPoll.mutate { longPoll in
            longPoll._poll = { query in
                if let _ = query as? LongPollCounterpartiesQuery {
                    return self.getCounterpartiesSubject
                        .map {
                            $0 as Decodable & Sendable
                        }
                        .eraseToAnyPublisher()
                } else if let _ = query as? LongPollSpendingsHistoryQuery {
                    return self.getSpendingsHistorySubject
                        .map {
                            $0 as Decodable & Sendable
                        }
                        .eraseToAnyPublisher()
                } else {
                    fatalError()
                }
            }
        }
    }
}

private actor MockOfflineMutableRepository: SpendingsOfflineMutableRepository {
    var spendingCounterpariesUpdates: [ [SpendingsPreview] ] = []
    var spendingHisoryUpdatesById: [User.ID: [[IdentifiableSpending]]] = [:]

    func updateSpendingCounterparties(_ counterparties: [SpendingsPreview]) async {
        spendingCounterpariesUpdates.append(counterparties)
    }

    func updateSpendingsHistory(counterparty: User.ID, history: [IdentifiableSpending]) async {
        let updates = spendingHisoryUpdatesById[counterparty, default: []] + [history]
        spendingHisoryUpdatesById[counterparty] = updates
    }
}

@Suite struct SpendingsRepositoryTests {

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
            getCounterpartiesResponse: counterparties.map(SpendingsPreviewDto.init)
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        var spendingCounterpartiesIterator = await repository
            .spendingCounterpartiesUpdated()
            .values
            .makeAsyncIterator()
        async let spendingCounterpartiesFromPublisher = spendingCounterpartiesIterator.next()

        // when

        let counterpartiesFromRepository = try await repository.refreshSpendingCounterparties()

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(counterpartiesFromRepository == counterparties)
        #expect(await apiProvider.getCounterpartiesCalledCount == 1)
        #expect(await offlineRepository.spendingCounterpariesUpdates == [counterparties])
        #expect(await spendingCounterpartiesFromPublisher == counterparties)

        timeout.cancel()
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
            getCounterpartiesResponse: counterparties.map(SpendingsPreviewDto.init)
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        var spendingCounterpartiesIterator = await repository
            .spendingCounterpartiesUpdated()
            .values
            .makeAsyncIterator()
        async let spendingCounterpartiesFromPublisher = spendingCounterpartiesIterator.next()

        // when

        apiProvider.getCounterpartiesSubject.send(
            LongPollCounterpartiesQuery.Update(category: .counterparties)
        )

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(await apiProvider.getCounterpartiesCalledCount == 1)
        #expect(await offlineRepository.spendingCounterpariesUpdates == [counterparties])
        #expect(await spendingCounterpartiesFromPublisher == counterparties)

        timeout.cancel()
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
            getSpendingsHistoryResponse: [counterparty: history.map(IdentifiableDealDto.init)]
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        var spendingsHistoryIterator = await repository
            .spendingsHistoryUpdated(for: counterparty)
            .values
            .makeAsyncIterator()
        async let spendingsHistoryFromPublisher = spendingsHistoryIterator.next()

        // when

        let historyFromRepository = try await repository.refreshSpendingsHistory(counterparty: counterparty)

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(historyFromRepository == history)
        #expect(await apiProvider.getSpendingsHistoryCalls == [counterparty])
        #expect(await offlineRepository.spendingHisoryUpdatesById[counterparty] == [history])
        #expect(await spendingsHistoryFromPublisher == history)

        timeout.cancel()
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
            getSpendingsHistoryResponse: [counterparty: history.map(IdentifiableDealDto.init)]
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )
        var spendingsHistoryIterator = await repository
            .spendingsHistoryUpdated(for: counterparty)
            .values
            .makeAsyncIterator()
        async let spendingsHistoryFromPublisher = spendingsHistoryIterator.next()

        // when

        apiProvider.getSpendingsHistorySubject.send(
            LongPollSpendingsHistoryQuery.Update(
                category: .spendings(uid: counterparty)
            )
        )

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(await apiProvider.getSpendingsHistoryCalls == [counterparty])
        #expect(await offlineRepository.spendingHisoryUpdatesById[counterparty] == [history])
        #expect(await spendingsHistoryFromPublisher == history)

        timeout.cancel()
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
            getDealResponse: [deal.id: DealDto(domain: deal.spending)]
        )
        let offlineRepository = MockOfflineMutableRepository()
        let repository = DefaultSpendingsRepository(
            api: apiProvider.api,
            longPoll: apiProvider.mockLongPoll,
            logger: .shared,
            offline: offlineRepository,
            taskFactory: taskFactory
        )

        // when

        let dealFromRepository = try await repository.getSpending(id: deal.id)

        // then

        let timeout = Task {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(dealFromRepository == deal.spending)
        #expect(await apiProvider.getDealCalls == [deal.id])

        timeout.cancel()
    }
}
