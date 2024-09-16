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

        #expect(await persistency.getRefreshToken() == refreshToken)
    }

    @Test func testUpdateRefreshToken() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(refreshToken: newRefreshToken)

        // then

        #expect(await persistency.getRefreshToken() == newRefreshToken)
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

        #expect(await awaken?.getRefreshToken() == refreshToken)
    }

    @Test func testUpdatedTokenFromAwake() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(refreshToken: newRefreshToken)
        await persistency.close()
        let awaken = await persistencyFactory.awake(host: host)

        // then

        #expect(await awaken?.getRefreshToken() == newRefreshToken)
    }

    @Test func testProfile() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .me,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
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
        await persistency.update(profile: profile)

        // then

        #expect(await persistency.getProfile() == profile)
    }

    @Test func testNoProfile() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.getProfile() == nil)
    }

    @Test func testUserId() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.userId() == host)
    }

    @Test func testUsers() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .me,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let friend = UserDto(
            login: UUID().uuidString,
            friendStatus: .friends,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host.id, refreshToken: refreshToken)
        await persistency.update(users: [host, friend])

        // then

        for user in [host, friend] {
            #expect(await persistency.user(id: user.id) == user)
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

        #expect(await persistency.user(id: UUID().uuidString) == nil)
    }

    @Test func testFriends() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let subscription = UserDto(
            login: UUID().uuidString,
            friendStatus: .outgoingRequest,
            displayName: "sub name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let friend = UserDto(
            login: UUID().uuidString,
            friendStatus: .friends,
            displayName: "some name",
            avatar: UserDto.Avatar(
                id: nil
            )
        )
        let friends: [FriendshipKindDto: [UserDto]] = [
            .friends: [friend],
            .subscription: [subscription]
        ]
        let query = Set(FriendshipKindDto.allCases)

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(friends: friends, for: query)

        // then

        let friendsFromDb = await persistency.getFriends(set: query)
        #expect(friendsFromDb?.keys == friends.keys)
        for (key, value) in friends {
            #expect(value == friendsFromDb?[key])
        }
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.friends])) == nil)
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.subscriber])) == nil)
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.subscription])) == nil)
        #expect(await persistency.getFriends(set: Set([.subscriber, .friends])) == nil)
        #expect(await persistency.getFriends(set: Set([.subscription, .friends])) == nil)
    }

    @Test func testNoFriends() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.friends])) == nil)
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.subscriber])) == nil)
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.subscription])) == nil)
        #expect(await persistency.getFriends(set: Set([.subscriber, .friends])) == nil)
        #expect(await persistency.getFriends(set: Set([.subscription, .friends])) == nil)
        #expect(await persistency.getFriends(set: Set(FriendshipKindDto.allCases)) == nil)
    }

    @Test func testNoSpendingCounterparties() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.getSpendingCounterparties() == nil)
    }

    @Test func testSpendingCounterparties() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let counterparties = [
            SpendingsPreviewDto(counterparty: UUID().uuidString, balance: ["USD": 16]),
            SpendingsPreviewDto(counterparty: UUID().uuidString, balance: ["RUB": -13])
        ]

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.updateSpendingCounterparties(counterparties)

        // then

        #expect(await persistency.getSpendingCounterparties() == counterparties)
    }

    @Test func testNoSpendingsHistory() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency.getSpendingsHistory(counterparty: UUID().uuidString) == nil)
    }

    @Test func testSpendingsHistory() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let counterparty = UUID().uuidString
        let history: [IdentifiableDealDto] = [
            IdentifiableDealDto(
                id: UUID().uuidString,
                deal: DealDto(
                    timestamp: 123,
                    details: "456",
                    cost: 789,
                    currency: "RUB",
                    spendings: [
                        SpendingDto(
                            userId: UUID().uuidString,
                            cost: 234
                        )
                    ]
                )
            ),
            IdentifiableDealDto(
                id: UUID().uuidString,
                deal: DealDto(
                    timestamp: 123,
                    details: "456",
                    cost: 789,
                    currency: "RUB",
                    spendings: [
                        SpendingDto(
                            userId: UUID().uuidString,
                            cost: 234
                        )
                    ]
                )
            )
        ]

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.updateSpendingsHistory(counterparty: counterparty, history: history)

        // then

        #expect(await persistency.getSpendingsHistory(counterparty: counterparty) == history)
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

        #expect(await persistencyFactory.awake(host: host) == nil)
    }
}
