import AppBase
import Logging
import Entities
import SpendingsScreen
import SpendingsRepository
import UsersRepository

public final class DefaultSpendingsFactory {
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private let hostId: User.Identifier
    private let logger: Logger

    public init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        hostId: User.Identifier,
        logger: Logger
    ) {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        self.hostId = hostId
        self.logger = logger
    }
}

extension DefaultSpendingsFactory: SpendingsFactory {
    public func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions> {
        await SpendingsModel(
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            hostId: hostId,
            logger: logger
        )
    }
}
