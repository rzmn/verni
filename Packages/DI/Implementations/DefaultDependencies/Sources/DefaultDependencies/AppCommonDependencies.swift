import DI
import Domain
import Infrastructure
internal import Api
internal import DefaultValidationUseCasesImplementation

final class AppCommonDependencies: AppCommon {
    private let api: ApiProtocol
    let avatarsRepository: AvatarsRepository
    let saveCredentialsUseCase: SaveCredendialsUseCase

    let localEmailValidationUseCase: EmailValidationUseCase
    let localPasswordValidationUseCase: PasswordValidationUseCase

    let infrastructure: InfrastructureLayer

    init(
        api: ApiProtocol,
        avatarsRepository: AvatarsRepository,
        saveCredentialsUseCase: SaveCredendialsUseCase,
        infrastructure: InfrastructureLayer
    ) {
        self.api = api
        self.saveCredentialsUseCase = saveCredentialsUseCase
        self.avatarsRepository = avatarsRepository
        self.infrastructure = infrastructure
        self.localEmailValidationUseCase = LocalValidationUseCases()
        self.localPasswordValidationUseCase = LocalValidationUseCases()
    }
}
