import Domain
import Api
import Combine
import Logging
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultProfileRepository {
    public let logger: Logger
    private let api: ApiProtocol
    private let offline: ProfileOfflineMutableRepository
    private let subject = PassthroughSubject<Domain.Profile, Never>()
    private var subscriptions = Set<AnyCancellable>()

    public init(api: ApiProtocol, logger: Logger, offline: ProfileOfflineMutableRepository) {
        self.api = api
        self.offline = offline
        self.logger = logger

        subject.sink { [weak self] profile in
            self?.logI { "profile updated \(profile)" }
        }.store(in: &subscriptions)
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
        Task.detached { [weak self] in
            guard let self else { return }
            await offline.update(profile: profile)
        }
        subject.send(profile)
        logI { "refresh ok" }
        return profile
    }
}

extension DefaultProfileRepository: Loggable {}
