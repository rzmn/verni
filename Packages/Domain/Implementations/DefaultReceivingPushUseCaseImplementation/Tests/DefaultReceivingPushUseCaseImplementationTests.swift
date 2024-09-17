import Testing
import Foundation
import Domain
@testable import AsyncExtensions
@testable import DefaultReceivingPushUseCaseImplementation

actor MockUsersRepository: UsersRepository {
    var getUsersCalls = [[User.ID]]()
    var searchUsersCalls = [String]()

    func getUsers(ids: [User.ID]) async throws(GeneralError) -> [User] {
        getUsersCalls.append(ids)

        return ids.map {
            User(
                id: $0,
                status: .friend,
                displayName: "display name of \($0)",
                avatar: nil
            )
        }
    }

    func searchUsers(query: String) async throws(GeneralError) -> [User] {
        searchUsersCalls.append(query)
        return []
    }
}

actor MockFriendsRepository: FriendsRepository {
    var refreshFriendsCalls = [FriendshipKindSet]()
    private let friendsUpdatedBroadcast: AsyncSubject<[FriendshipKind: [User]]>

    init(taskFactory: TaskFactory) {
        friendsUpdatedBroadcast = AsyncSubject(taskFactory: taskFactory)
    }

    func friendsUpdated(
        ofKind kind: FriendshipKindSet
    ) async -> any AsyncBroadcast<[FriendshipKind: [User]]> {
        friendsUpdatedBroadcast
    }

    func refreshFriends(
        ofKind kind: FriendshipKindSet
    ) async throws(GeneralError) -> [FriendshipKind: [User]] {
        refreshFriendsCalls.append(kind)
        return [
            .friends: [
                User(
                    id: UUID().uuidString,
                    status: .friend,
                    displayName: "display name",
                    avatar: nil
                )
            ]
        ]
    }
}

actor MockSpendingsRepository: SpendingsRepository {
    var refreshSpendingCounterpartiesCalls: [Void] = [Void]()
    var refreshSpendingsHistoryCalls = [User.ID]()
    var getSpendingCalls = [Spending.ID]()

    private let spendingCounterpartiesUpdatedBroadcast: AsyncSubject<[SpendingsPreview]>
    private let spendingsHistoryUpdatedBroadcast: AsyncSubject<[IdentifiableSpending]>

    init(taskFactory: TaskFactory) {
        spendingCounterpartiesUpdatedBroadcast = AsyncSubject(taskFactory: taskFactory)
        spendingsHistoryUpdatedBroadcast = AsyncSubject(taskFactory: taskFactory)
    }

    func refreshSpendingCounterparties() async throws(GeneralError) -> [SpendingsPreview] {
        refreshSpendingCounterpartiesCalls.append(())
        return [SpendingsPreview(counterparty: UUID().uuidString, balance: [.russianRuble: 123])]
    }

    func refreshSpendingsHistory(counterparty: User.ID) async throws(GetSpendingsHistoryError) -> [IdentifiableSpending] {
        refreshSpendingsHistoryCalls.append(counterparty)
        return [
            IdentifiableSpending(
                spending: Spending(
                    date: Date(),
                    details: "spending details",
                    cost: 123,
                    currency: .russianRuble,
                    participants: [
                        counterparty: 123
                    ]
                ),
                id: UUID().uuidString
            )
        ]
    }

    func getSpending(id: Spending.ID) async throws(GetSpendingError) -> Spending {
        getSpendingCalls.append(id)
        return Spending(
            date: Date(),
            details: "spending details",
            cost: 123,
            currency: .russianRuble,
            participants: [
                UUID().uuidString: 123
            ]
        )
    }

    func spendingCounterpartiesUpdated() async -> any AsyncBroadcast<[SpendingsPreview]> {
        spendingCounterpartiesUpdatedBroadcast
    }

    func spendingsHistoryUpdated(for id: User.ID) async -> any AsyncBroadcast<[IdentifiableSpending]> {
        spendingsHistoryUpdatedBroadcast
    }
}

@Suite struct DefaultReceivingPushUseCaseTests {
    @Test func testReceivePush() async throws {
        let taskFactory = TestTaskFactory()
        let useCase = DefaultReceivingPushUseCase(
            usersRepository: MockUsersRepository(),
            friendsRepository: MockFriendsRepository(taskFactory: taskFactory),
            spendingsRepository: MockSpendingsRepository(taskFactory: taskFactory),
            logger: .shared.with(prefix: "[DefaultReceivingPushUseCaseTests] ")
        )
        let jsonString =
"""
{
    "aps": {
        "mutable-content": 1,
        "alert": {
            "title": "Friend request has been accepted",
            "body": "From: cad72fc3-8361-4bf9-b7ae-04d8156f2d84"
        }
    },
    "d": {
        "t": 0,
        "p": {
            "t": "cad72fc3-8361-4bf9-b7ae-04d8156f2d84"
        }
    }
}
"""
        let jsonData = jsonString.data(using: .utf8)!
        let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as! [AnyHashable: Any]
        let content = try await useCase.process(rawPushPayload: jsonDict)
        print("\(content)")
    }
}
