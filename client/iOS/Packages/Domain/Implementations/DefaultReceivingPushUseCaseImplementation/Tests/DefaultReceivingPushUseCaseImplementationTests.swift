import XCTest
import Domain
import Combine
@testable import DefaultReceivingPushUseCaseImplementation

class MockUsersRepository: UsersRepository {
    var getUsersCalls = [[User.ID]]()
    var searchUsersCalls = [String]()

    func getUsers(ids: [User.ID]) async -> Result<[User], GeneralError> {
        getUsersCalls.append(ids)

        return .success(ids.map {
            User(
                id: $0,
                status: .friend,
                displayName: "display name of \($0)",
                avatar: nil
            )
        })
    }
    
    func searchUsers(query: String) async -> Result<[User], GeneralError> {
        searchUsersCalls.append(query)
        return .success([])
    }
}

class MockFriendsRepository: FriendsRepository {
    var refreshFriendsCalls = [FriendshipKindSet]()

    func refreshFriends(ofKind kind: FriendshipKindSet) async -> Result<[FriendshipKind: [User]], GeneralError> {
        refreshFriendsCalls.append(kind)
        return .success([
            .friends: [
                User(
                    id: UUID().uuidString,
                    status: .friend,
                    displayName: "display name",
                    avatar: nil
                )
            ]
        ])
    }
    
    func friendsUpdated(ofKind kind: FriendshipKindSet) async -> AnyPublisher<[FriendshipKind: [User]], Never> {
        PassthroughSubject().eraseToAnyPublisher()
    }
}

class MockSpendingsRepository: SpendingsRepository {
    var refreshSpendingCounterpartiesCalls: [Void] = [Void]()
    var refreshSpendingsHistoryCalls = [User.ID]()
    var getSpendingCalls = [Spending.ID]()

    func refreshSpendingCounterparties() async -> Result<[SpendingsPreview], GeneralError> {
        refreshSpendingCounterpartiesCalls.append(())
        return .success([SpendingsPreview(counterparty: UUID().uuidString, balance: [.russianRuble: 123])])
    }
    
    func refreshSpendingsHistory(counterparty: User.ID) async -> Result<[IdentifiableSpending], GetSpendingsHistoryError> {
        refreshSpendingsHistoryCalls.append(counterparty)
        return .success([
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
        ])
    }
    
    func getSpending(id: Spending.ID) async -> Result<Spending, GetSpendingError> {
        getSpendingCalls.append(id)
        return .success(Spending(
            date: Date(),
            details: "spending details",
            cost: 123,
            currency: .russianRuble,
            participants: [
                UUID().uuidString: 123
            ]
        ))
    }
    
    func spendingCounterpartiesUpdated() async -> AnyPublisher<[SpendingsPreview], Never> {
        PassthroughSubject().eraseToAnyPublisher()
    }
    
    func spendingsHistoryUpdated(for id: User.ID) async -> AnyPublisher<[IdentifiableSpending], Never> {
        PassthroughSubject().eraseToAnyPublisher()
    }
    

}

class DefaultReceivingPushUseCaseTests: XCTestCase {
    func testReceivePush() async {
        let useCase = DefaultReceivingPushUseCase(
            usersRepository: MockUsersRepository(),
            friendsRepository: MockFriendsRepository(),
            spendingsRepository: MockSpendingsRepository(),
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
        let jsonDict = try! JSONSerialization.jsonObject(with: jsonData) as! [AnyHashable: Any]
        let content = await useCase.process(rawPushPayload: jsonDict)!
        print("\(content)")
    }
}
