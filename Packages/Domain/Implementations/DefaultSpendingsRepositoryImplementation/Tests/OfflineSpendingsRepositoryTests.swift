import Testing
import Domain
import Foundation
import PersistentStorage
@testable import DefaultSpendingsRepositoryImplementation
@testable import MockPersistentStorage

private actor PersistencyProvider {
    let persistency: PersistencyMock

    var getSpendingCounterpartiesCalledCount = 0
    var updateSpendingCounterpartiesCalls: [ [BalanceDto] ] = []

    var getSpendingHistoryCalledCount: [UserDto.Identifier: Int] = [:]
    var updateSpendingHistoryCalls: [ (UserDto.Identifier, [IdentifiableExpenseDto]) ] = []

    var balance: [BalanceDto]?
    var spendingHistory = [UserDto.Identifier: [IdentifiableExpenseDto]]()

    init() async {
        persistency = PersistencyMock()
        await persistency.performIsolated { persistency in
            persistency.getBlock = { anyDescriptor in
                if anyDescriptor as? Index<AnyDescriptor<Unkeyed, [BalanceDto]>> != nil {
                    await self.performIsolated { `self` in
                        self.getSpendingCounterpartiesCalledCount += 1
                    }
                    return await self.balance
                } else if let descriptor = anyDescriptor as? Index<AnyDescriptor<UserDto.Identifier, [IdentifiableExpenseDto]>> {
                    await self.performIsolated { `self` in
                        self.getSpendingHistoryCalledCount[descriptor.key] = self.getSpendingHistoryCalledCount[descriptor.key, default: 0] + 1
                    }
                    return await self.spendingHistory[descriptor.key]
                } else {
                    fatalError()
                }
            }
            persistency.updateBlock = { anyDescriptor, anyObject in
                if let descriptor = anyDescriptor as? Index<AnyDescriptor<UserDto.Identifier, [IdentifiableExpenseDto]>>, let history = anyObject as? [IdentifiableExpenseDto] {
                    self.performIsolated { `self` in
                        self.updateSpendingHistoryCalls.append((descriptor.key, history))
                        self.spendingHistory[descriptor.key] = history
                    }
                } else if anyDescriptor as? Index<AnyDescriptor<Unkeyed, [BalanceDto]>> != nil, let balance = anyObject as? [BalanceDto] {
                    self.performIsolated { `self` in
                        self.updateSpendingCounterpartiesCalls.append(balance)
                        self.balance = balance
                    }
                }
            }
        }
    }
}

@Suite struct OfflineSpendingsRepositoryTests {

    @Test func testGetCounterparties() async throws {

        // given

        let provider = await PersistencyProvider()
        let couterparties = [
            SpendingsPreview(
                counterparty: UUID().uuidString,
                balance: [
                    .russianRuble: 19
                ]
            )
        ]
        let repository = DefaultSpendingsOfflineRepository(
            persistency: provider.persistency
        )

        // when

        await repository.updateSpendingCounterparties(couterparties)
        let couterpartiesFromRepository = await repository.getSpendingCounterparties()

        // then

        #expect(couterpartiesFromRepository == couterparties)
        #expect(await provider.getSpendingCounterpartiesCalledCount == 1)
        #expect(await provider.updateSpendingCounterpartiesCalls == [couterparties.map(BalanceDto.init)])
    }

    @Test func testNoCounterparties() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultSpendingsOfflineRepository(
            persistency: provider.persistency
        )

        // when

        let counterparties = await repository.getSpendingCounterparties()

        // then

        #expect(counterparties == nil)
        #expect(await provider.getSpendingCounterpartiesCalledCount == 1)
    }

    @Test func testGetSpendingsHistory() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultSpendingsOfflineRepository(
            persistency: provider.persistency
        )
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

        // when

        await repository.updateSpendingsHistory(counterparty: counterparty, history: history)
        let historyFromRepository = await repository.getSpendingsHistory(counterparty: counterparty)

        // then

        #expect(historyFromRepository == history)
        #expect(await provider.updateSpendingHistoryCalls.map(\.0) == [counterparty])
        #expect(await provider.updateSpendingHistoryCalls.map(\.1) == [history.map(IdentifiableExpenseDto.init)])
        #expect(await provider.getSpendingHistoryCalledCount[counterparty, default: 0] == 1)
    }

    @Test func testNoSpendingsHistory() async throws {

        // given

        let provider = await PersistencyProvider()
        let repository = DefaultSpendingsOfflineRepository(
            persistency: provider.persistency
        )
        let counterparty = UUID().uuidString

        // when

        let historyFromRepository = await repository.getSpendingsHistory(counterparty: counterparty)

        // then

        #expect(historyFromRepository == nil)
        #expect(await provider.getSpendingHistoryCalledCount[counterparty, default: 0] == 1)
    }
}
