import DI
import Domain
internal import Api
internal import DefaultValidationUseCasesImplementation

class AppCommonDependencies: AppCommon {
    private let api: ApiProtocol
    let avatarsRepository: AvatarsRepository
    let saveCredentialsUseCase: SaveCredendialsUseCase

    lazy var localEmailValidationUseCase: EmailValidationUseCase = LocalValidationUseCases()
    lazy var localPasswordValidationUseCase: PasswordValidationUseCase = LocalValidationUseCases()

    init(api: ApiProtocol, avatarsRepository: AvatarsRepository, saveCredentialsUseCase: SaveCredendialsUseCase) {
        self.api = api
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.avatarsRepository = avatarsRepository
    }
}
