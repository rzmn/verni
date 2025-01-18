import Entities
import InfrastructureLayer
import CredentialsFormatValidationUseCase
import AvatarsRepository
import SaveCredendialsUseCase

public protocol AppCommon: Sendable {
    var localEmailValidationUseCase: EmailValidationUseCase { get }
    var localPasswordValidationUseCase: PasswordValidationUseCase { get }

    var avatarsRepository: AvatarsRemoteDataSource { get }
    var saveCredentialsUseCase: SaveCredendialsUseCase { get }

    var infrastructure: InfrastructureLayer { get }
}

public protocol AppCommonCovertible: Sendable {
    var appCommon: AppCommon { get }
}
