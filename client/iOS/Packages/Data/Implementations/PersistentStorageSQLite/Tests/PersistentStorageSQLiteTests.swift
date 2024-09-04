import Foundation
import Testing
import PersistentStorage
import DataTransferObjects
@testable import PersistentStorageSQLite

extension SQLitePersistencyFactory {
    static func test() -> SQLitePersistencyFactory {
        SQLitePersistencyFactory(
            logger: .shared.with(prefix: "[test] "),
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: "db")
        )
    }
}

@Suite struct PersistentStorageSQLiteTests {

    init() async {
        let dbDirectory = await SQLitePersistencyFactory.test().dbDirectory
        try? FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        guard let content = try? FileManager.default.contentsOfDirectory(at: dbDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for url in content {
            try? FileManager.default.removeItem(at: url)
        }
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
        autoreleasepool {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                let persistency = try await SQLitePersistencyFactory.test()
                    .create(hostId: hostId, refreshToken: initialRefreshToken)
                await persistency.update(refreshToken: newToken)
                await persistency.close()
                semaphore.signal()
            }
            semaphore.wait()
        }

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
        await persistency.update(users: [host])
        let hostFromDb = await persistency.getHostInfo()

        #expect(host.id == hostFromDb?.user.id)
        #expect(host.friendStatus == hostFromDb?.user.friendStatus)
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
}
