import Testing
import Base
import TestInfrastructure
import Filesystem
import Foundation
import SQLite
import PersistentStorage
@testable import PersistentStorageSQLite

@Suite(.serialized)
struct PersistentStorageFactoryTests {
    @Test func testFailedToCreateDatabaseFileManagerCreate() async throws {

        // given

        let infrastructure = modify(TestInfrastructureLayer()) {
            var manager = $0.testFileManager
            manager.createDirectoryBlock = { _ throws(CreateDirectoryError) in
                throw .urlIsReferringToFile
            }
            $0.testFileManager = manager
        }
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString

        // when

        do {
            let _ = try await persistencyFactory
                .create(host: host, refreshToken: refreshToken)
            Issue.record()
        } catch {
            guard let error = error as? CreateDirectoryError, case .urlIsReferringToFile = error else {
                Issue.record("\(error)")
                return
            }
            // then
        }
    }

    @Test func testFailedToCreateDatabaseFileManagerAwake() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let infrastructureWithFailingCreateDirectory = modify(infrastructure) {
            var manager = $0.testFileManager
            manager.createDirectoryBlock = { _ throws(CreateDirectoryError) in
                throw .urlIsReferringToFile
            }
            $0.testFileManager = manager
        }
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructureWithFailingCreateDirectory.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructureWithFailingCreateDirectory.taskFactory,
            fileManager: infrastructureWithFailingCreateDirectory.fileManager
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let _ = try await SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        ).create(host: host, refreshToken: refreshToken)

        // when

        let persistency = await persistencyFactory
            .awake(host: host)

        // then

        #expect(persistency == nil)
    }

    @Test func testAwakeNoHost() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        let host = UUID().uuidString

        // when

        let persistency = await persistencyFactory
            .awake(host: host)

        // then

        #expect(persistency == nil)
    }

    @Test func testAwakeCannotListExistedDbs() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let infrastructureWithFailingListDirectory = modify(infrastructure) {
            var manager = $0.testFileManager
            manager.listDirectoryBlock = { _, _ throws(ListDirectoryError) in
                throw .noSuchDirectory
            }
            $0.testFileManager = manager
        }
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructureWithFailingListDirectory.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructureWithFailingListDirectory.taskFactory,
            fileManager: infrastructureWithFailingListDirectory.fileManager
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let _ = try await SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        ).create(host: host, refreshToken: refreshToken)

        // when

        let persistency = await persistencyFactory
            .awake(host: host)

        // then

        #expect(persistency == nil)
    }

    @Test func testUpdateNonExistentDescriptor() async throws {

        // given

        struct SomeDescriptor: Descriptor {
            struct SomeStruct: Hashable, Codable {}
            typealias Key = SomeStruct
            typealias Value = SomeStruct
            let id: String = "id"
        }
        let descriptor = SomeDescriptor()
        let index = descriptor.index(for: SomeDescriptor.SomeStruct())
        let value = SomeDescriptor.SomeStruct()
        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
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
        await persistency.update(value: value, for: index)

        // then

        #expect(await persistency[index] == nil)
    }

    @Test func testNilAwakeAfterInvalidate() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // when

        await persistency.invalidate()
        let awaken = await persistencyFactory
            .awake(host: host)

        // then

        #expect(awaken == nil)
    }

    @Test func testCreateAfterInvalidate() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let persistencyFactory = try SQLitePersistencyFactory(
            logger: infrastructure.logger,
            dbDirectory: FileManager.default.temporaryDirectory.appending(component: UUID().uuidString),
            taskFactory: infrastructure.taskFactory,
            fileManager: infrastructure.fileManager
        )
        let host = UUID().uuidString
        let refreshToken = UUID().uuidString
        let newRefreshToken = UUID().uuidString
        let persistency = try await persistencyFactory
            .create(host: host, refreshToken: refreshToken)

        // when

        await persistency.invalidate()
        let newCreated = try await persistencyFactory
            .create(host: host, refreshToken: newRefreshToken)

        // then

        #expect(await newCreated.refreshToken == newRefreshToken)
    }

    @Test func testCreateFailedFailedToCreateTables() async throws {

        // given

        struct SomeDescriptor: Descriptor {
            struct SomeStruct: Hashable, Codable {}
            typealias Key = SomeStruct
            typealias Value = SomeStruct
            let id: String = "sqlite_xxx"
        }
        let descriptor = SomeDescriptor()
        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
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

        do {
            let _ = try await persistencyFactory
                .create(
                    host: host.id,
                    descriptors: DescriptorTuple(content: descriptor),
                    refreshToken: refreshToken
                )
            Issue.record()
        } catch {
            // then
        }
    }

    @Test func testCreateFailedFailedInsertRefreshToken() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
            displayName: "some name",
            avatarId: nil
        )
        let infrastructure = TestInfrastructureLayer()
        let connection = try Connection()

        // when

        do {
            let _ = try await SQLitePersistency(
                database: connection,
                invalidator: {},
                hostId: host.id,
                refreshToken: nil,
                logger: infrastructure.logger
            )
            Issue.record()
        } catch {
            // then
        }
    }

    @Test func testCreateFailedNoRefreshToken() async throws {

        // given

        let host = UserDto(
            login: UUID().uuidString,
            friendStatus: .currentUser,
            displayName: "some name",
            avatarId: nil
        )
        let infrastructure = TestInfrastructureLayer()
        let connection = try Connection()
        typealias Expression = SQLite.Expression
        try connection.run(
            Table(Schema.refreshToken.id).create { table in
                table.column(
                    Expression<CodableBlob<Unkeyed>>(Schema.identifierKey), primaryKey: true)
                table.column(Expression<CodableBlob<String>>(Schema.valueKey))
            }
        )

        // when

        do {
            let _ = try await SQLitePersistency(
                database: connection,
                invalidator: {},
                hostId: host.id,
                refreshToken: nil,
                logger: infrastructure.logger
            )
            Issue.record()
        } catch {
            // then
        }
    }

    @Test @StorageActor func testAwakeFailedNoRefreshToken() async throws {
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
        if let connection = (persistency as? SQLitePersistency)?.database {
            try connection.run(
                Table(Schema.refreshToken.id)
                    .delete()
            )
        } else {
            Issue.record()
            return
        }
        await persistency.close()
        let awaken = await persistencyFactory.awake(host: host)

        // then

        #expect(awaken == nil)
    }

    @Test func testGetWhenUpdatedButAlreadyClosed() async throws {

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
        await persistency.close()
        let newProfile = ProfileDto(
            user: host,
            email: "a@b.com",
            emailVerified: true
        )
        await persistency.update(value: newProfile, for: Schema.profile.unkeyed)

        // then

        #expect(await persistency[Schema.profile.unkeyed] == profile)
    }

    @Test func testUpdateWhenAlreadyClosed() async throws {

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
        await persistency.close()
        await persistency.update(value: profile, for: Schema.profile.unkeyed)

        // then

        #expect(await persistency[Schema.profile.unkeyed] == nil)
    }

}
