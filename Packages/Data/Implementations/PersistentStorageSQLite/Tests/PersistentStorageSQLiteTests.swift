import Foundation
import Testing
import PersistentStorage
import DataTransferObjects
@testable import Base
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
        await persistency.update(value: newRefreshToken, for: Schema.refreshToken.unkeyed)

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
        await persistency.update(value: newRefreshToken, for: Schema.refreshToken.unkeyed)
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
        await persistency.update(value: profile, for: Schema.profile.unkeyed)

        // then

        #expect(await persistency[Schema.profile.unkeyed] == profile)
    }

    @Test func testNoProfile() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schema.profile.unkeyed] == nil)
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
            await persistency.update(value: user, for: Schema.users.index(for: user.id))
        }

        // then

        for user in [host, friend] {
            #expect(await persistency[Schema.users.index(for: user.id)] == user)
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

        #expect(await persistency[Schema.users.index(for: UUID().uuidString)] == nil)
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
        let query = FriendshipKindSetDto(FriendshipKindDto.allCases)

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        await persistency.update(value: friends, for: Schema.friends.index(for: query))

        // then

        let friendsFromDb = await persistency[Schema.friends.index(for: query)]
        #expect(friendsFromDb?.keys == friends.keys)
        for (key, value) in friends {
            #expect(value == friendsFromDb?[key])
        }
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.friends]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscriber]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscription]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscriber, .friends]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscription, .friends]))] == nil)
    }

    @Test func testNoFriends() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.friends]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscriber]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscription]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscriber, .friends]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto([.subscription, .friends]))] == nil)
        #expect(await persistency[Schema.friends.index(for: FriendshipKindSetDto(FriendshipKindDto.allCases))] == nil)
    }

    @Test func testNoSpendingCounterparties() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schema.spendingCounterparties.unkeyed] == nil)
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
        await persistency.update(value: counterparties, for: Schema.spendingCounterparties.unkeyed)

        // then

        #expect(await persistency[Schema.spendingCounterparties.unkeyed] == counterparties)
    }

    @Test func testNoSpendingsHistory() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schema.spendingsHistory.index(for: UUID().uuidString)] == nil)
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
        await persistency.update(value: history, for: Schema.spendingsHistory.index(for: counterparty))

        // then

        #expect(await persistency[Schema.spendingsHistory.index(for: counterparty)] == history)
    }
    
    @Test func testFailedToCreateDatabaseFileManagerCreate() async throws {
        
        // given
        
        let expectedError = InternalError.error("create failed", underlying: nil)
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: taskFactory,
            pathManager: MockPathManager(
                createDirectory: { _ in throw expectedError }
            )
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        
        // when
        
        do {
            let _ = try await persistencyFactory
                .create(host: host, refreshToken: refreshToken)
            Issue.record()
        } catch {
            
            // then
            
            #expect(expectedError.description == (error as? InternalError)?.description)
        }
    }
    
    @Test func testFailedToCreateDatabaseFileManagerAwake() async throws {
        
        // given
        
        let expectedError = InternalError.error("create failed", underlying: nil)
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: taskFactory,
            pathManager: MockPathManager(
                createDirectory: { _ in throw expectedError }
            )
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let _ = try await self.persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        
        // when
        
        let persistency = await persistencyFactory
            .awake(host: host)
            
        // then
            
        #expect(persistency == nil)
    }
    
    @Test func testAwakeNoHost() async throws {
        
        // given
        
        let host = UUID().uuidString
        
        // when
        
        let persistency = await persistencyFactory
            .awake(host: host)
            
        // then
            
        #expect(persistency == nil)
    }
    
    @Test func testAwakeCannotListExistedDbs() async throws {
        
        // given
        
        let expectedError = InternalError.error("list failed", underlying: nil)
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: taskFactory,
            pathManager: MockPathManager(
                createDirectory: { _ in },
                listDirectory: { _, _ in throw expectedError }
            )
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let _ = try await self.persistencyFactory
            .create(host: host, refreshToken: refreshToken)
        
        // when
        
        let persistency = await persistencyFactory
            .awake(host: host)
            
        // then
            
        #expect(persistency == nil)
    }
}
