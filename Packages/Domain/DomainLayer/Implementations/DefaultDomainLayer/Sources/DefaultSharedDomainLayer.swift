import DomainLayer
import DataLayer
import InfrastructureLayer
import AsyncExtensions
import CredentialsFormatValidationUseCase
import SaveCredendialsUseCase
import AvatarsRepository
import Logging
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
    let logger: Logger
    
    init(infrastructure: InfrastructureLayer) async throws {
        data = try DefaultDataLayer(
            logger: infrastructure.logger.with(
                scope: .dataLayer
            ),
            infrastructure: infrastructure
        )
        self.infrastructure = infrastructure
        
        self.logger = infrastructure.logger
            .with(scope: .domainLayer(.shared))
        
        self.saveCredentialsUseCase = DefaultSaveCredendialsUseCase(
            website: "https://verni.app",
            logger: logger.with(
                scope: .saveCredentials
            )
        )
        self.localEmailValidationUseCase = LocalValidationUseCases()
        self.localPasswordValidationUseCase = LocalValidationUseCases()
        self.avatarsRepository = await DefaultAvatarsRepository(
            userId: .sandbox,
            sync: data.sandbox.sync,
            infrastructure: infrastructure,
            logger: logger.with(
                scope: .images
            )
        )
        logI { "initialized" }
    }
}

extension DefaultSharedDomainLayer: Loggable {}
