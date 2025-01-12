import Domain
import Api
import Logging
import Base
import AsyncExtensions
internal import ApiDomainConvenience

public actor DefaultProfileRepository {
    public let logger: Logger
    private let api: APIProtocol
    private let offline: ProfileOfflineMutableRepository
    private let profile: ExternallyUpdatable<Domain.Profile>
    private let taskFactory: TaskFactory
    private let subscription: BlockAsyncSubscription<Domain.Profile>

    public init(
        api: APIProtocol,
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
    public func profileUpdated() async -> any AsyncBroadcast<Domain.Profile> {
        await profile.relevant
    }

    public func refreshProfile() async throws(GeneralError) -> Domain.Profile {
        logI { "refresh" }
        let response: Operations.GetProfile.Output
        do {
            response = try await api.getProfile()
        } catch {
            throw GeneralError(error)
        }
        let profileDto: Components.Schemas.Profile
        switch response {
        case .ok(let success):
            switch success.body {
            case .json(let payload):
                profileDto = payload.response
            }
        case .unauthorized(let apiError):
            throw GeneralError(apiError)
        case .conflict(let apiError):
            throw GeneralError(apiError)
        case .internalServerError(let apiError):
            throw GeneralError(apiError)
        case .undocumented(statusCode: let statusCode, let body):
            logE { "got undocumented response on getProfile: \(statusCode) \(body)" }
            throw GeneralError(UndocumentedBehaviour(context: (statusCode, body)))
        }
        let profile = Profile(dto: profileDto)
        await self.profile.update(profile)
        logI { "refresh ok" }
        return profile
    }
}

extension DefaultProfileRepository: Loggable {}
