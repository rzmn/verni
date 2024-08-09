import DI
import Domain
internal import Api
internal import DefaultValidationUseCasesImplementation
internal import DefaultAvatarsRepositoryImplementation

class AppCommonDependencies {
    private let api: ApiProtocol
    private let _avatarsRepository: AvatarsRepository

    init(api: ApiProtocol, avatarsRepository: AvatarsRepository) {
        self.api = api
        self._avatarsRepository = avatarsRepository
    }
}

extension AppCommonDependencies: AppCommon {
    func avatarsRepository() -> AvatarsRepository {
        _avatarsRepository
    }
    
    func localEmailValidationUseCase() -> any EmailValidationUseCase {
        LocalValidationUseCases()
    }

    func passwordValidationUseCase() -> any PasswordValidationUseCase {
        LocalValidationUseCases()
    }
}
