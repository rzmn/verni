import Foundation
import Testing
import PersistentStorage
import DataTransferObjects
import Base
@testable import AsyncExtensions
@testable import PersistentStorageSQLite

@Suite(.serialized) struct PersistentStorageSQLiteTests {
    private let taskFactory = TestTaskFactory()
    private let persistencyFactory: SQLitePersistencyFactory

    init() throws {
        persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: taskFactory
        )
    }

    @Test func testGetRefreshToken() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.refreshToken == refreshToken)
    }

    @Test func testUpdateRefreshToken() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: newRefreshToken, for: Schemas.refreshToken.unkeyedIndex)

        // then

        #expect(await persistency.refreshToken == newRefreshToken)
    }

    @Test func testGetRefreshTokenFromAwake() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.close()
        let awaken = await persistencyFactory.awake(host: host)

        // then

        #expect(await awaken?.refreshToken == refreshToken)
    }

    @Test func testUpdatedTokenFromAwake() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: newRefreshToken, for: Schemas.refreshToken.unkeyedIndex)
        await persistency.close()
        let awaken = await persistencyFactory.awake(host: host)

        // then

        #expect(await awaken?.refreshToken == newRefreshToken)
    }

    @Test func testProfile() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
            displayName: "some name",
            avatarId: nil
        )
        let profile = ProfileDto(
            user: host,
            email: "a@b.com",
            emailVerified: true
        )
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host.id, refreshToken: refreshToken)
        await persistency.update(value: profile, for: Schemas.profile.unkeyedIndex)

        // then

        #expect(await persistency[Schemas.profile.unkeyedIndex] == profile)
    }

    @Test func testNoProfile() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schemas.profile.unkeyedIndex] == nil)
    }

    @Test func testUserId() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.userId == host)
    }

    @Test func testUsers() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
            displayName: "some name",
            avatarId: nil
        )
        let friend = UserDto(
            login: UUID().uuidString,
            friendStatus: .friends,
            displayName: "some name",
            avatarId: nil
        )
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host.id, refreshToken: refreshToken)
        for user in [host, friend] {
            await persistency.update(value: user, for: Schemas.users.index(for: user.id))
        }

        // then

        for user in [host, friend] {
            #expect(await persistency[Schemas.users.index(for: user.id)] == user)
        }
    }

    @Test func testNoUsers() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schemas.users.index(for: UUID().uuidString)] == nil)
    }

    @Test func testFriends() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let subscription = UserDto(
            login: UUID().uuidString,
            friendStatus: .outgoingRequest,
            displayName: "sub name",
            avatarId: nil
        )
        let friend = UserDto(
            login: UUID().uuidString,
            friendStatus: .friends,
            displayName: "some name",
            avatarId: nil
        )
        let friends: [FriendshipKindDto: [UserDto]] = [
            .friends: [friend],
            .subscription: [subscription]
        ]
        let query = Set(FriendshipKindDto.allCases)

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: friends, for: Schemas.friends.index(for: query))

        // then

        let friendsFromDb = await persistency[Schemas.friends.index(for: query)]
        #expect(friendsFromDb?.keys == friends.keys)
        for (key, value) in friends {
            #expect(value == friendsFromDb?[key])
        }
        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.friends]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.subscriber]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.subscription]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([.subscriber, .friends]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([.subscription, .friends]))] == nil)
    }

    @Test func testNoFriends() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.friends]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.subscriber]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([FriendshipKindDto.subscription]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([.subscriber, .friends]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set([.subscription, .friends]))] == nil)
        #expect(await persistency[Schemas.friends.index(for: Set(FriendshipKindDto.allCases))] == nil)
    }

    @Test func testNoSpendingCounterparties() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schemas.spendingCounterparties.unkeyedIndex] == nil)
    }

    @Test func testSpendingCounterparties() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let counterparties = [
            BalanceDto(counterparty: UUID().uuidString, currencies: ["USD": 16]),
            BalanceDto(counterparty: UUID().uuidString, currencies: ["RUB": -13])
        ]

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: counterparties, for: Schemas.spendingCounterparties.unkeyedIndex)

        // then

        #expect(await persistency[Schemas.spendingCounterparties.unkeyedIndex] == counterparties)
    }

    @Test func testNoSpendingsHistory() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schemas.spendingsHistory.index(for: UUID().uuidString)] == nil)
    }

    @Test func testSpendingsHistory() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let counterparty = UUID().uuidString
        let history: [IdentifiableExpenseDto] = [
            IdentifiableExpenseDto(
                id: UUID().uuidString,
                deal: ExpenseDto(
                    timestamp: 123,
                    details: "456",
                    cost: 789,
                    currency: "RUB",
                    shares: [
                        ShareOfExpenseDto(
                            userId: UUID().uuidString,
                            cost: 234
                        )
                    ],
                    attachments: []
                )
            ),
            IdentifiableExpenseDto(
                id: UUID().uuidString,
                deal: ExpenseDto(
                    timestamp: 123,
                    details: "456",
                    cost: 789,
                    currency: "RUB",
                    shares: [
                        ShareOfExpenseDto(
                            userId: UUID().uuidString,
                            cost: 234
                        )
                    ],
                    attachments: []
                )
            )
        ]

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: history, for: Schemas.spendingsHistory.index(for: counterparty))

        // then

        #expect(await persistency[Schemas.spendingsHistory.index(for: counterparty)] == history)
    }

    @Test func testInvalidate() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.invalidate()
        try await taskFactory.runUntilIdle()

        // then

        #expect(await (persistency as? SQLitePersistency)?.shouldInvalidate == true)
    }
}
