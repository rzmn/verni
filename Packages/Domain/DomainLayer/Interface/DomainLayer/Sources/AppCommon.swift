import Domain
import Infrastructure

public protocol AppCommon: Sendable {
    var localEmailValidationUseCase: EmailValidationUseCase { get }
    var localPasswordValidationUseCase: PasswordValidationUseCase { get }

    var avatarsRepository: AvatarsRepository { get }
    var saveCredentialsUseCase: SaveCredendialsUseCase { get }

    var infrastructure: InfrastructureLayer { get }
}

public protocol AppCommonCovertible: Sendable {
    var appCommon: AppCommon { get }
}
