import Foundation
import Testing
import PersistentStorage
import TestInfrastructure
import Filesystem
import SQLite
@testable import Base
@testable import PersistentStorageSQLite

@Suite(.serialized) struct PersistentStorageTests {
    @Test func testGetRefreshToken() async throws {

        // given

        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

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
        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )

        // when

        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // then

        #expect(await persistency[Schema.users.index(for: UUID().uuidString)] == nil)
    }
}
