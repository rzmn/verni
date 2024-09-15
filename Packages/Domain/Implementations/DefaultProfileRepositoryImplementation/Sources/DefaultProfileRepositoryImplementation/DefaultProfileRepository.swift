import Domain
import Api
import Combine
import Logging
import Base
internal import DataTransferObjects
internal import ApiDomainConvenience

extension AsyncBroadcast.Subscription: @retroactive CancellableStream {
    public typealias Element = T
}

public actor DefaultProfileRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let offline: ProfileOfflineMutableRepository
    private let profile: ExternallyUpdatable<Domain.Profile>
    private let taskFactory: TaskFactory
    private let subscription: AsyncBroadcast<Domain.Profile>.BlockSubscription

    public init(
        api: ApiProtocol,
        logger: Logger,
        offline: ProfileOfflineMutableRepository,
        profile: ExternallyUpdatable<Domain.Profile>,
        taskFactory: TaskFactory
    ) async {
        self.api = api
        self.offline = offline
        self.logger = logger
        self.taskFactory = taskFactory
        self.profile = profile
        subscription = await profile.relevant.subscribe { [offline] profile in
            taskFactory.task {
                await offline.update(profile: profile)
            }
        }
    }
}

extension DefaultProfileRepository: ProfileRepository {
    public func profileUpdated() async -> any CancellableStream<Domain.Profile> {
        await profile.relevant.subscription()
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
        await self.profile.update(profile)
        logI { "refresh ok" }
        return profile
    }
}

extension DefaultProfileRepository: Loggable {}
