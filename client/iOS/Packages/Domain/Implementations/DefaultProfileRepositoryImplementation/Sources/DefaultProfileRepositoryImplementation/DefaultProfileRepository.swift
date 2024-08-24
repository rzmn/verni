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
    
    public func refreshProfile() async -> Result<Domain.Profile, GeneralError> {
        logI { "refresh" }
        switch await api.run(method: Profile.GetInfo()) {
        case .success(let dto):
            let profile = Profile(dto: dto)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(profile: profile)
            }
            subject.send(profile)
            logI { "refresh ok" }
            return .success(profile)
        case .failure(let error):
            logI { "refresh failed error: \(error)" }
            return .failure(GeneralError(apiError: error))
        }
    }
}

extension DefaultProfileRepository: Loggable {}
