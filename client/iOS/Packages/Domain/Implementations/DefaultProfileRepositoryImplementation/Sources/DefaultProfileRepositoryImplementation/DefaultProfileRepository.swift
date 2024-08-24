import Domain
import Api
import Combine
internal import DataTransferObjects
internal import ApiDomainConvenience

public class DefaultProfileRepository {
    private let api: ApiProtocol
    private let offline: ProfileOfflineMutableRepository
    private let subject = PassthroughSubject<Domain.Profile, Never>()

    public init(api: ApiProtocol, offline: ProfileOfflineMutableRepository) {
        self.api = api
        self.offline = offline
    }
}

extension DefaultProfileRepository: ProfileRepository {
    public func profileUpdated() async -> AnyPublisher<Domain.Profile, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func refreshProfile() async -> Result<Domain.Profile, GeneralError> {
        switch await api.run(method: Profile.GetInfo()) {
        case .success(let dto):
            let profile = Profile(dto: dto)
            Task.detached { [weak self] in
                guard let self else { return }
                await offline.update(profile: profile)
            }
            subject.send(profile)
            return .success(profile)
        case .failure(let error):
            return .failure(GeneralError(apiError: error))
        }
    }
}
