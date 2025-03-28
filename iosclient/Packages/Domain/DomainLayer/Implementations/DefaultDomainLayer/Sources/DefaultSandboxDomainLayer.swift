import DomainLayer
import AuthUseCase
import UsersRepository
import SpendingsRepository
import DataLayer
import Logging
import InfrastructureLayer
internal import DefaultUsersRepository
internal import DefaultSpendingsRepository

public final class DefaultSandboxDomainLayer: SandboxDomainLayer {
    public let logger: Logger
    public let usersRepository: UsersRepository
    public let spendingsRepository: SpendingsRepository
    private let defaultSharedDomainLayer: DefaultSharedDomainLayer
    public var shared: SharedDomainLayer {
        defaultSharedDomainLayer
    }
    
    public init(
        infrastructure: InfrastructureLayer,
        data: DataLayer
    ) async {
        let shared: DefaultSharedDomainLayer
        do {
            shared = try await DefaultSharedDomainLayer(
                infrastructure: infrastructure,
                data: data
            )
        } catch {
            let message = "failed to init shared domain layer error: \(error)"
            infrastructure.logger.logE { message }
            fatalError(message)
        }
        
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
    
    public func authUseCase() -> any AuthUseCase<HostedDomainLayer> {
        DefaultAuthUseCase(
            sharedDomain: defaultSharedDomainLayer,
            defaults: defaultSharedDomainLayer.data.userDefaults,
            logger: logger
                .with(scope: .auth)
        )
    }
}

extension DefaultSandboxDomainLayer: Loggable {}
