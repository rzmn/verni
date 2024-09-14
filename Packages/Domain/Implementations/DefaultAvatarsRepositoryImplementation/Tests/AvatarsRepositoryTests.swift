import Testing
import Logging
import Foundation
import Domain
import Api
import DataTransferObjects
@testable import MockApiImplementation
@testable import DefaultAvatarsRepositoryImplementation
@testable import Base

private actor MockOfflineRepository: AvatarsOfflineRepository, AvatarsOfflineMutableRepository {
    var getCalls: [Avatar.ID] = []
    var storeCalls: [(Data, Avatar.ID)] = []
    var storage = [Avatar.ID: Data]()

    func get(for id: Avatar.ID) async -> Data? {
        getCalls.append(id)
        return storage[id]
    }

    func store(data: Data, for id: Avatar.ID) async {
        storeCalls.append((data, id))
        storage[id] = data
    }
}

private actor ApiProvider {
    let api: MockApi
    let getResponse: [Avatar.ID: Data]
    var getCalls: [ [Avatar.ID] ] = []

    init(getResponse: [Avatar.ID: Data]) async {
        self.getResponse = getResponse
        api = MockApi()
        await api.mutate { api in
            api._runMethodWithParams = { method in
                await self.mutate { s in
                    if let method = method as? Avatars.Get {
                        s.getCalls.append(method.parameters.ids)
                    }
                }
                if let _ = method as? Avatars.Get {
                    return getResponse.map {
                        AvatarDataDto(id: $0.key, base64Data: $0.value.base64EncodedString())
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
