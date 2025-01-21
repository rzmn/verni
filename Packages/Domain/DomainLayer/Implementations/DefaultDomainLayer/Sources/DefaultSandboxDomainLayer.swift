import DomainLayer
import AuthUseCase
import UsersRepository
import SpendingsRepository
import DataLayer
internal import DefaultDataLayer
internal import DefaultUsersRepository
internal import DefaultSpendingsRepository

final class DefaultSandboxDomainLayer: SandboxDomainLayer {    
    let usersRepository: UsersRepository
    let spendingsRepository: SpendingsRepository
    private let defaultSharedDomainLayer: DefaultSharedDomainLayer
    var shared: SharedDomainLayer {
        defaultSharedDomainLayer
    }
    
    init(shared: DefaultSharedDomainLayer) async {
        self.defaultSharedDomainLayer = shared
        usersRepository = await DefaultUsersRepository(
            userId: .sandbox,
            sync: defaultSharedDomainLayer.data.sandbox.sync,
            infrastructure: shared.infrastructure,
            logger: shared.infrastructure.logger.with(
                prefix: "🪪"
            )
        )
        spendingsRepository = await DefaultSpendingsRepository(
            userId: .sandbox,
            sync: defaultSharedDomainLayer.data.sandbox.sync,
            infrastructure: shared.infrastructure,
            logger: shared.infrastructure.logger.with(
                prefix: "💸"
            )
        )
    }
    
    func authUseCase() -> any AuthUseCase<HostedDomainLayer> {
        DefaultAuthUseCase(
            sharedDomain: defaultSharedDomainLayer,
            logger: shared.infrastructure.logger
                .with(prefix: "🔐")
        )
    }
}
