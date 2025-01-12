import Testing
import Logging
import Foundation
import Base
import TestInfrastructure
@testable import AsyncExtensions
@testable import DefaultAvatarsRepositoryImplementation

@Suite struct AvatarsOfflineRepositoryTests {
    let container: URL

    init() throws {
        self.container = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
    }

    @Test func testGetNoData() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let repository = try DefaultAvatarsOfflineRepository(
            container: container,
            logger: infrastructure.logger
        )
        let aid = UUID().uuidString

        // when

        let data = repository.get(for: aid)

        // then

        #expect(data == nil)
    }

    @Test func testGetData() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let repository = try DefaultAvatarsOfflineRepository(
            container: container,
            logger: infrastructure.logger
        )
        let aid = UUID().uuidString
        let avatar = UUID().uuidString.data(using: .utf8)!

        // when

        await repository.store(data: avatar, for: aid)
        let avatarFromRepository = repository.get(for: aid)

        // then

        #expect(avatar == avatarFromRepository)
    }

    @Test func testGetDataConcurrent() async throws {

        // given

        let infrastructure = TestInfrastructureLayer()
        let repository = try DefaultAvatarsOfflineRepository(
            container: container,
            logger: infrastructure.logger
        )
        let avatars = [
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!,
            UUID().uuidString: UUID().uuidString.data(using: .utf8)!
        ]

        // when

        for avatar in avatars {
            await repository.store(data: avatar.value, for: avatar.key)
        }
        let avatarsFromRepository = await repository.getConcurrent(taskFactory: infrastructure.taskFactory, ids: Array(avatars.keys))

        // then

        #expect(avatars == avatarsFromRepository)
    }
}
