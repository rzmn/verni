import Testing
import Logging
import Foundation
import Domain
import Api
import DataTransferObjects
import Base
@testable import AsyncExtensions
@testable import MockApiImplementation
@testable import DefaultAvatarsRepositoryImplementation

private actor MockOfflineRepository: AvatarsOfflineRepository, AvatarsOfflineMutableRepository {
    var getCalls: [Avatar.Identifier] = []
    var storeCalls: [(Data, Avatar.Identifier)] = []
    var storage = [Avatar.Identifier: Data]()

    func get(for id: Avatar.Identifier) async -> Data? {
        getCalls.append(id)
        return storage[id]
    }

    func store(data: Data, for id: Avatar.Identifier) async {
        storeCalls.append((data, id))
        storage[id] = data
    }
}

private actor ApiProvider {
    let api: MockApi
    let getResponse: [Avatar.Identifier: Data]
    var getCalls: [ [Avatar.Identifier] ] = []

    init(getResponse: [Avatar.Identifier: Data]) async {
        self.getResponse = getResponse
        api = MockApi()
        await api.performIsolated { api in
            api.runMethodWithParamsBlock = { method in
                await self.performIsolated { `self` in
                    if let method = method as? Avatars.Get {
                        self.getCalls.append(method.parameters.ids)
                    }
                }
                if let _ = method as? Avatars.Get {
                    return getResponse.map {
                        ImageDto(id: $0.key, base64: $0.value.base64EncodedString())
                    }.reduce(into: [:]) { dict, kv in
                        dict[kv.id] = kv
                    }
                } else {
                    fatalError()
                }
            }
        }
    }
}

@Suite struct AvatarsRepositoryTests {

    @Test func testGet() async throws {

        // given

        let avatars = [
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!
        ]
        let provider = await ApiProvider(getResponse: avatars)
        let offlineRepository = MockOfflineRepository()
        let taskFactory = TestTaskFactory()
        let repository = DefaultAvatarsRepository(
            api: provider.api,
            taskFactory: taskFactory,
            offlineRepository: offlineRepository,
            offlineMutableRepository: offlineRepository,
            logger: .shared
        )

        // when

        let avatarsFromRepository = await repository.get(ids: Array(avatars.keys))

        // then

        #expect(await provider.getCalls.map(Set.init) == [Set(avatars.keys)])
        #expect(avatarsFromRepository == avatars)
    }

    @Test func testGetPartiallyCached() async throws {

        // given

        let avatars = [
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!
        ]
        let cachedAvatars = [
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!
        ]
        let provider = await ApiProvider(getResponse: avatars)
        let offlineRepository = MockOfflineRepository()
        let taskFactory = TestTaskFactory()
        let repository = DefaultAvatarsRepository(
            api: provider.api,
            taskFactory: taskFactory,
            offlineRepository: offlineRepository,
            offlineMutableRepository: offlineRepository,
            logger: .shared
        )
        let allAvatars = [avatars.keys, cachedAvatars.keys].flatMap { $0 }

        // when

        for (id, avatar) in cachedAvatars {
            await offlineRepository.store(data: avatar, for: id)
        }
        let avatarsFromRepository = await repository.get(ids: allAvatars)

        // then

        #expect(await provider.getCalls.map(Set.init) == [Set(avatars.keys)])
        #expect(avatarsFromRepository == avatars.reduce(into: cachedAvatars, { dict, kv in
            dict[kv.key] = kv.value
        }))
    }

    @Test func testGetAllCached() async throws {

        // given

        let avatars = [
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!
        ]
        let provider = await ApiProvider(getResponse: avatars)
        let offlineRepository = MockOfflineRepository()
        let taskFactory = TestTaskFactory()
        let repository = DefaultAvatarsRepository(
            api: provider.api,
            taskFactory: taskFactory,
            offlineRepository: offlineRepository,
            offlineMutableRepository: offlineRepository,
            logger: .shared
        )

        // when

        for (id, avatar) in avatars {
            await offlineRepository.store(data: avatar, for: id)
        }
        let avatarsFromRepository = await repository.get(ids: Array(avatars.keys))

        // then

        #expect(await provider.getCalls.map(Set.init) == [])
        #expect(avatarsFromRepository == avatars)
    }
}
