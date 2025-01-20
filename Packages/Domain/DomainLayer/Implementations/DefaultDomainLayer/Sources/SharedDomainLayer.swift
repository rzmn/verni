import DomainLayer
import DataLayer
import InfrastructureLayer
import AsyncExtensions
internal import DefaultAvatarsRepositoryImplementation
internal import DefaultValidationUseCasesImplementation
internal import DefaultSaveCredendialsUseCaseImplementation

final class DefaultSharedDomainLayer: SharedDomainLayer {
    let localEmailValidationUseCase: EmailValidationUseCase
    let localPasswordValidationUseCase: PasswordValidationUseCase
    var avatarsRepository: AvatarsRemoteDataSource {
        get async {
            _avatarsRepository.value
        }
    }
    let saveCredentialsUseCase: SaveCredendialsUseCase
    let infrastructure: InfrastructureLayer
    
    private let _avatarsRepository: AsyncLazyObject<AvatarsRepository>
    
    private var webcredentials: String {
        "https://verni.app"
    }
    
    init(
        data: DataLayer,
        infrastructure: InfrastructureLayer
    ) {
        let logger = infrastructure.logger
        self.infrastructure = infrastructure
        self.saveCredentialsUseCase = DefaultSaveCredendialsUseCase(
            website: webcredentials,
            logger: logger.with(
                prefix: "🔐"
            )
        )
        self.localEmailValidationUseCase = LocalValidationUseCases()
        self.localPasswordValidationUseCase = LocalValidationUseCases()
        _avatarsRepository = AsyncLazyObject {
            DefaultAvatarsRepository(
                userId: .sandbox,
                sync: data.sandbox.sync,
                infrastructure: infrastructure,
                logger: logger.with(
                    prefix: "🧑‍🎨"
                )
            )
        }
    }
}
