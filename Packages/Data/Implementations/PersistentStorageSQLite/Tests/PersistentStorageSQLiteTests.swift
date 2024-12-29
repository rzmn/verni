import Foundation
import Testing
import PersistentStorage
import DataTransferObjects
import TestInfrastructure
import Filesystem
import SQLite
@testable import Base
@testable import PersistentStorageSQLite

@Suite(.serialized) struct PersistentStorageSQLiteTests {
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
        await persistency.update(value: counterparties, for: Schema.spendingCounterparties.unkeyed)

        // then

        #expect(await persistency[Schema.spendingCounterparties.unkeyed] == counterparties)
    }

    @Test func testNoSpendingsHistory() async throws {

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
        await persistency.update(value: history, for: Schema.spendingsHistory.index(for: counterparty))

        // then

        #expect(await persistency[Schema.spendingsHistory.index(for: counterparty)] == history)
    }
    
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
            print("[debug] error: \(error)")
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
            print("[debug] error: \(error)")
        }
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
