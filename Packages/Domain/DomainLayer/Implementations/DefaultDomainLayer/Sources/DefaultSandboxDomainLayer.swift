import DomainLayer
import AuthUseCase
import UsersRepository
import SpendingsRepository
import DataLayer
import Logging
internal import DefaultDataLayer
internal import DefaultUsersRepository
internal import DefaultSpendingsRepository

final class DefaultSandboxDomainLayer: SandboxDomainLayer {
    let logger: Logger
    let usersRepository: UsersRepository
    let spendingsRepository: SpendingsRepository
    private let defaultSharedDomainLayer: DefaultSharedDomainLayer
    var shared: SharedDomainLayer {
        defaultSharedDomainLayer
    }
    
    init(shared: DefaultSharedDomainLayer) async {
        self.defaultSharedDomainLayer = shared
        self.logger = shared.infrastructure.logger
            .with(scope: .domainLayer(.sandbox))
        usersRepository = await DefaultUsersRepository(
            userId: .sandbox,
            sync: defaultSharedDomainLayer.data.sandbox.sync,
            infrastructure: shared.infrastructure,
            logger: logger
                .with(scope: .users)
        )
        spendingsRepository = await DefaultSpendingsRepository(
            userId: .sandbox,
            sync: defaultSharedDomainLayer.data.sandbox.sync,
            infrastructure: shared.infrastructure,
            logger: logger
                .with(scope: .spendings)
        )
        logI { "initialized" }
    }
    
    func authUseCase() -> any AuthUseCase<HostedDomainLayer> {
        DefaultAuthUseCase(
            sharedDomain: defaultSharedDomainLayer,
            logger: logger
                .with(scope: .auth)
        )
    }
}

extension DefaultSandboxDomainLayer: Loggable {}
