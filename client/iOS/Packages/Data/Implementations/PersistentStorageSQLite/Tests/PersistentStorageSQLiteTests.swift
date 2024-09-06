import Foundation
import Testing
import PersistentStorage
import DataTransferObjects
@testable import PersistentStorageSQLite

extension SQLitePersistencyFactory {
    static var directory: URL {
        FileManager.default.temporaryDirectory.appending(component: "db")
    }

    static func test() -> SQLitePersistencyFactory {
        SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: directory
        )
    }
}

@Suite(.serialized) struct PersistentStorageSQLiteTests {

    init() throws {
        let directory = SQLitePersistencyFactory.directory
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: nil) {
            try FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    @Test func testInitialToken() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString

        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: hostId, refreshToken: initialRefreshToken)

        let token = await persistency.getRefreshToken()
        #expect(initialRefreshToken == token)
        await persistency.invalidate()
    }

    @Test func testUpdateToken() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString

        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: hostId, refreshToken: initialRefreshToken)

        let newToken = UUID().uuidString
        await persistency.update(refreshToken: newToken)
        let newTokenFromDb = await persistency.getRefreshToken()
        #expect(newToken == newTokenFromDb)
        await persistency.invalidate()
    }

    @Test func testUpdatedTokenFromAwake() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString
        let newToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: hostId, refreshToken: initialRefreshToken)
        await persistency.update(refreshToken: newToken)
        await persistency.close()

        let awaken = await SQLitePersistencyFactory.test().awake()
        let newTokenFromAwake = await awaken?.getRefreshToken()
        print("\(initialRefreshToken)")
        print("\(newToken)")
        print("\(newTokenFromAwake ?? "nil")")
        #expect(newToken == newTokenFromAwake)

        await awaken?.invalidate()
    }

    @Test func testHostInfo() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)
        await persistency.update(hostInfo: ProfileDto(user: host, email: "", emailVerified: false))
        let hostFromDb = await persistency.getHostInfo()

        #expect(host.id == hostFromDb?.user.id)
        #expect(host.friendStatus == hostFromDb?.user.friendStatus)
    }

    @Test func testNoHostInfo() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)
        let hostFromDb = await persistency.getHostInfo()

        #expect(hostFromDb == nil)
        #expect(await persistency.userId() == host.id)
    }

    @Test func testUserId() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: hostId, refreshToken: initialRefreshToken)
        #expect(await persistency.userId() == hostId)
    }

    @Test func testUsers() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let other = UserDto(login: UUID().uuidString, friendStatus: .outgoingRequest, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)
        await persistency.update(users: [host, other])

        for user in [host, other] {
            let userFromDb = await persistency.user(id: user.id)
            #expect(user.id == userFromDb?.id)
            #expect(user.friendStatus == userFromDb?.friendStatus)
        }
    }

    @Test func testFriends() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let outgoing = UserDto(login: UUID().uuidString, friendStatus: .outgoingRequest, displayName: "", avatar: UserDto.Avatar(id: nil))
        let friend = UserDto(login: UUID().uuidString, friendStatus: .friends, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)

        let friends: [FriendshipKindDto: [UserDto]] = [.friends: [friend], .subscriber: [outgoing]]
        let query = Set(FriendshipKindDto.allCases)
        await persistency.updateFriends(friends, for: query)

        let friendsFromDb = await persistency.getFriends(set: query)
        #expect(friendsFromDb?.keys == friends.keys)
        for (key, value) in friends {
            #expect(value == friendsFromDb?[key])
        }
    }

    @Test func testNoFriends() async throws {
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: UUID().uuidString, refreshToken: UUID().uuidString)

        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.friends])) == nil)
        #expect(await persistency.getFriends(set: Set([FriendshipKindDto.subscriber])) == nil)
        #expect(await persistency.getFriends(set: Set(FriendshipKindDto.allCases)) == nil)
    }

    @Test func testNoSpendingCounterparties() async throws {
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: UUID().uuidString, refreshToken: UUID().uuidString)
        #expect(await persistency.getSpendingCounterparties() == nil)
    }

    @Test func testSpendingCounterparties() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let other = UserDto(login: UUID().uuidString, friendStatus: .outgoingRequest, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)
        let counterparties = [
            SpendingsPreviewDto(counterparty: other.id, balance: ["USD": 16])
        ]
        await persistency.updateSpendingCounterparties(counterparties)

        let counterpartiesFromDb = await persistency.getSpendingCounterparties()
        #expect(counterparties == counterpartiesFromDb)
    }

    @Test func testNoSpendingsHistory() async throws {
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: UUID().uuidString, refreshToken: UUID().uuidString)
        #expect(await persistency.getSpendingsHistory(counterparty: UUID().uuidString) == nil)
    }

    @Test func testSpendingsHistory() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me, displayName: "", avatar: UserDto.Avatar(id: nil))
        let other = UserDto(login: UUID().uuidString, friendStatus: .outgoingRequest, displayName: "", avatar: UserDto.Avatar(id: nil))
        let initialRefreshToken = UUID().uuidString
        let persistency = try await SQLitePersistencyFactory.test()
            .create(hostId: host.id, refreshToken: initialRefreshToken)
        let history: [IdentifiableDealDto] = [
            IdentifiableDealDto(id: UUID().uuidString, deal: DealDto(timestamp: 123, details: "456", cost: 789, currency: "RUB", spendings: [
                SpendingDto(userId: UUID().uuidString, cost: 234)
            ])),
            IdentifiableDealDto(id: UUID().uuidString, deal: DealDto(timestamp: 123, details: "456", cost: 789, currency: "RUB", spendings: [
                SpendingDto(userId: UUID().uuidString, cost: 234)
            ])),
        ]
        await persistency.updateSpendingsHistory(counterparty: other.id, history: history)
        let historyFromDb = await persistency.getSpendingsHistory(counterparty: other.id)
        #expect(history == historyFromDb)
    }
}
