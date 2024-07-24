import Foundation
import XCTest
import PersistentStorage
import DataTransferObjects
@testable import PersistentStorageSQLite

private class TestPersistencyFactory: SQLitePersistencyFactory {
    convenience init() {
        self.init(logger: .shared.with(prefix: "[test] "))
    }

    override var dbDirectory: URL {
        FileManager.default.temporaryDirectory
    }
}

class PersistentStorageSQLiteTests: XCTestCase {

    override func setUp() {
        let dbDirectory = TestPersistencyFactory().dbDirectory
        try? FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        guard let content = try? FileManager.default.contentsOfDirectory(at: dbDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for url in content {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func testInitialToken() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString

        let persistency = try await TestPersistencyFactory()
            .create(hostId: hostId, refreshToken: initialRefreshToken)

        let token = await persistency.getRefreshToken()
        XCTAssertTrue(initialRefreshToken == token)
        await persistency.invalidate()
    }

    func testUpdateToken() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString

        let persistency = try await TestPersistencyFactory()
            .create(hostId: hostId, refreshToken: initialRefreshToken)

        let newToken = UUID().uuidString
        await persistency.update(refreshToken: newToken)
        let newTokenFromDb = await persistency.getRefreshToken()
        XCTAssertTrue(newToken == newTokenFromDb)
        await persistency.invalidate()
    }

    func testUpdatedTokenFromAwake() async throws {
        let hostId = UUID().uuidString
        let initialRefreshToken = UUID().uuidString
        let newToken = UUID().uuidString
        autoreleasepool {
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                let persistency = try await TestPersistencyFactory()
                    .create(hostId: hostId, refreshToken: initialRefreshToken)
                await persistency.update(refreshToken: newToken)
                await persistency.close()
                semaphore.signal()
            }
            semaphore.wait()
        }

        let awaken = await TestPersistencyFactory().awake()
        let newTokenFromAwake = await awaken?.getRefreshToken()
        print("\(initialRefreshToken)")
        print("\(newToken)")
        print("\(newTokenFromAwake ?? "nil")")
        XCTAssertTrue(newToken == newTokenFromAwake)

        await awaken?.invalidate()
    }

    func testHostInfo() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me)
        let initialRefreshToken = UUID().uuidString
        let persistency = try await TestPersistencyFactory()
            .create(hostId: host.login, refreshToken: initialRefreshToken)
        await persistency.update(users: [host])
        let hostFromDb = await persistency.getHostInfo()

        XCTAssertTrue(host.login == hostFromDb?.login)
        XCTAssertTrue(host.friendStatus == hostFromDb?.friendStatus)
    }

    func testUsers() async throws {
        let host = UserDto(login: UUID().uuidString, friendStatus: .me)
        let other = UserDto(login: UUID().uuidString, friendStatus: .outgoingRequest)
        let initialRefreshToken = UUID().uuidString
        let persistency = try await TestPersistencyFactory()
            .create(hostId: host.login, refreshToken: initialRefreshToken)
        await persistency.update(users: [host, other])

        for user in [host, other] {
            let userFromDb = await persistency.user(id: user.login)
            XCTAssertTrue(user.login == userFromDb?.login)
            XCTAssertTrue(user.friendStatus == userFromDb?.friendStatus)
        }
    }
}
