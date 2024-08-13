import DI
import Domain
internal import Api
internal import DefaultValidationUseCasesImplementation
internal import DefaultAvatarsRepositoryImplementation

class AppCommonDependencies {
    private let api: ApiProtocol
    private let _avatarsRepository: AvatarsRepository
    private let _saveCredentialsUseCase: SaveCredendialsUseCase

    init(api: ApiProtocol, avatarsRepository: AvatarsRepository, saveCredentialsUseCase: SaveCredendialsUseCase) {
        self.api = api
        self._saveCredentialsUseCase = saveCredentialsUseCase
        self._avatarsRepository = avatarsRepository
    }
}

extension AppCommonDependencies: AppCommon {
    func saveCredentials() -> SaveCredendialsUseCase {
        _saveCredentialsUseCase
    }
    
    func avatarsRepository() -> AvatarsRepository {
        _avatarsRepository
    }
    
    func localEmailValidationUseCase() -> any EmailValidationUseCase {
        LocalValidationUseCases()
    }

    func localPasswordValidationUseCase() -> any PasswordValidationUseCase {
        LocalValidationUseCases()
    }
}
