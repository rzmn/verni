import DI
import Domain
internal import Api
internal import DefaultValidationUseCasesImplementation

final class AppCommonDependencies: AppCommon {
    private let api: ApiProtocol
    let avatarsRepository: AvatarsRepository
    let saveCredentialsUseCase: SaveCredendialsUseCase

    let localEmailValidationUseCase: EmailValidationUseCase
    let localPasswordValidationUseCase: PasswordValidationUseCase

    init(api: ApiProtocol, avatarsRepository: AvatarsRepository, saveCredentialsUseCase: SaveCredendialsUseCase) {
        self.api = api
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.avatarsRepository = avatarsRepository
        self.localEmailValidationUseCase = LocalValidationUseCases()
        self.localPasswordValidationUseCase = LocalValidationUseCases()
    }
}
