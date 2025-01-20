import Entities
import InfrastructureLayer
import CredentialsFormatValidationUseCase
import AvatarsRepository
import SaveCredendialsUseCase

public protocol SharedDomainLayer: Sendable {
    var localEmailValidationUseCase: EmailValidationUseCase { get }
    var localPasswordValidationUseCase: PasswordValidationUseCase { get }

    var avatarsRepository: AvatarsRepository { get async }
    var saveCredentialsUseCase: SaveCredendialsUseCase { get }

    var infrastructure: InfrastructureLayer { get }
}

public protocol SharedDomainLayerCovertible: SharedDomainLayer {
    var shared: SharedDomainLayer { get }
}

extension SharedDomainLayerCovertible {
    public var localEmailValidationUseCase: EmailValidationUseCase {
        shared.localEmailValidationUseCase
    }
    public var localPasswordValidationUseCase: PasswordValidationUseCase {
        shared.localPasswordValidationUseCase
    }
    public var avatarsRepository: AvatarsRepository {
        get async {
            await shared.avatarsRepository
        }
    }
    public var saveCredentialsUseCase: SaveCredendialsUseCase {
        shared.saveCredentialsUseCase
    }
    public var infrastructure: InfrastructureLayer {
        shared.infrastructure
    }
}
