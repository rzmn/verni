import Domain
import Api
import Combine
import Logging
import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

public actor DefaultProfileRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let offline: ProfileOfflineMutableRepository
    private let subject = PassthroughSubject<Domain.Profile, Never>()
    private let taskFactory: TaskFactory

    public init(
        api: ApiProtocol,
        logger: Logger,
        offline: ProfileOfflineMutableRepository,
        taskFactory: TaskFactory
    ) async {
        self.api = api
        self.offline = offline
        self.logger = logger
        self.taskFactory = taskFactory
    }
}

extension DefaultProfileRepository: ProfileRepository {
    public func profileUpdated() async -> AnyPublisher<Domain.Profile, Never> {
        subject.eraseToAnyPublisher()
    }

    public func refreshProfile() async throws(GeneralError) -> Domain.Profile {
        logI { "refresh" }
        let profile: Domain.Profile
        do {
            profile = Profile(dto: try await api.run(method: Profile.GetInfo()))
        } catch {
            logI { "refresh failed error: \(error)" }
            throw GeneralError(apiError: error)
        }
        taskFactory.detached {
            await self.offline.update(profile: profile)
        }
        subject.send(profile)
        logI { "refresh ok" }
        return profile
    }
}

extension DefaultProfileRepository: Loggable {}
