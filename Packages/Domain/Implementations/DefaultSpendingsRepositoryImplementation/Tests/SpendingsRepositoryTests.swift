import Testing
import DataTransferObjects
import Api
import Domain
import Combine
import Foundation
@testable import Base
@testable import DefaultSpendingsRepositoryImplementation
@testable import MockApiImplementation

private actor ApiProvider {
    let api: MockApi
    let mockLongPoll: MockLongPoll

    var getCounterpartiesCalledCount = 0
    private let getCounterpartiesResponse: [SpendingsPreviewDto]
    private let getCounterpartiesPublisher = PassthroughSubject<LongPollCounterpartiesQuery.Update, Never>().eraseToAnyPublisher()

    var getSpendingsHistoryCalls: [UserDto.ID] = []
    private let getSpendingsHistoryResponse: [UserDto.ID: [IdentifiableDealDto]]
    private let getSpendingsHistoryPublisher = PassthroughSubject<LongPollSpendingsHistoryQuery.Update, Never>().eraseToAnyPublisher()

    init(
        getCounterpartiesResponse: [SpendingsPreviewDto] = [],
        getSpendingsHistoryResponse: [UserDto.ID: [IdentifiableDealDto]] = [:]
    ) async {
        self.getCounterpartiesResponse = getCounterpartiesResponse
        self.getSpendingsHistoryResponse = getSpendingsHistoryResponse
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
                    }
                }
                if let method = method as? Spendings.GetDeals {
                    return self.getSpendingsHistoryResponse[method.parameters.counterparty]
                } else {
                    fatalError()
                }
            }
        }
        await mockLongPoll.mutate { longPoll in
            longPoll._poll = { query in
                if let _ = query as? LongPollCounterpartiesQuery {
                    return self.getCounterpartiesPublisher
                        .map {
                            $0 as Decodable & Sendable
                        }
                        .eraseToAnyPublisher()
                } else if let _ = query as? LongPollSpendingsHistoryQuery {
                    return self.getSpendingsHistoryPublisher
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
        let spendingCounterpartiesPublisher = await repository.spendingCounterpartiesUpdated()
        actor SubscriptionsBox {
            var subscriptions = Set<AnyCancellable>()
        }

        // when

        let spendingCounterpartiesNotification = taskFactory.detached {
            let box = SubscriptionsBox()
            return await box.mutate { box in
                return await withCheckedContinuation(isolation: box) { continuation in
                    spendingCounterpartiesPublisher
                        .sink { preview in
                            continuation.resume(returning: preview)
                        }
                        .store(in: &box.subscriptions)
                }
            }
        }
        let counterpartiesFromRepository = try await repository.refreshSpendingCounterparties()

        // then

        let timeout = Task.detached {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(counterpartiesFromRepository == counterparties)
        #expect(await apiProvider.getCounterpartiesCalledCount == 1)
        #expect(await offlineRepository.spendingCounterpariesUpdates == [counterparties])
        #expect(await spendingCounterpartiesNotification.value == counterparties)

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
        let getSpendingsHistoryPublisher = await repository.spendingsHistoryUpdated(for: counterparty)
        actor SubscriptionsBox {
            var subscriptions = Set<AnyCancellable>()
        }

        // when

        let spendingCounterpartiesNotification = taskFactory.detached {
            let box = SubscriptionsBox()
            return await box.mutate { box in
                return await withCheckedContinuation(isolation: box) { continuation in
                    getSpendingsHistoryPublisher
                        .sink { history in
                            continuation.resume(returning: history)
                        }
                        .store(in: &box.subscriptions)
                }
            }
        }
        let historyFromRepository = try await repository.refreshSpendingsHistory(counterparty: counterparty)

        // then

        let timeout = Task.detached {
            try await Task.sleep(timeInterval: 5)
            if !Task.isCancelled {
                Issue.record("\(#function): timeout failed")
            }
        }
        try await taskFactory.runUntilIdle()

        #expect(historyFromRepository == history)
        #expect(await apiProvider.getSpendingsHistoryCalls == [counterparty])
        #expect(await offlineRepository.spendingHisoryUpdatesById[counterparty] == [history])
        #expect(await spendingCounterpartiesNotification.value == history)

        timeout.cancel()
    }
}
