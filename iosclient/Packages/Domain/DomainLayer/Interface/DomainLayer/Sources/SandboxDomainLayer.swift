import Entities
import AuthUseCase
import UsersRepository
import SpendingsRepository

public protocol SandboxDomainLayer: SharedDomainLayerCovertible {
    var usersRepository: UsersRepository { get }
    var spendingsRepository: SpendingsRepository { get }
    
    func authUseCase() -> any AuthUseCase<HostedDomainLayer>
}
