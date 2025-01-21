import DomainLayer
import DataLayer
import InfrastructureLayer
import AsyncExtensions
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import AvatarsRepository
internal import DefaultDataLayer
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultValidationUseCasesImplementation
internal import DefaultSaveCredendialsUseCaseImplementation

final class DefaultSharedDomainLayer: SharedDomainLayer {
    let localEmailValidationUseCase: EmailValidationUseCase
    let localPasswordValidationUseCase: PasswordValidationUseCase
    let saveCredentialsUseCase: SaveCredendialsUseCase
    let infrastructure: InfrastructureLayer
    let avatarsRepository: AvatarsRepository
    
    let data: DataLayer
    
    init(infrastructure: InfrastructureLayer) async throws {
        data = try DefaultDataLayer(
            logger: infrastructure.logger,
            infrastructure: infrastructure
        )
        let logger = infrastructure.logger
        self.infrastructure = infrastructure
        self.saveCredentialsUseCase = DefaultSaveCredendialsUseCase(
            website: "https://verni.app",
            logger: logger.with(
                prefix: "🔐"
            )
        )
        self.localEmailValidationUseCase = LocalValidationUseCases()
        self.localPasswordValidationUseCase = LocalValidationUseCases()
        self.avatarsRepository = await DefaultAvatarsRepository(
            userId: .sandbox,
            sync: data.sandbox.sync,
            infrastructure: infrastructure,
            logger: logger.with(
                prefix: "🧑‍🎨"
            )
        )
    }
}
