import AppBase
import Logging
import SpendingsScreen
import SpendingsRepository
import UsersRepository

public final class DefaultSpendingsFactory {
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private let logger: Logger

    public init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        logger: Logger
    ) {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        self.logger = logger
    }
}

extension DefaultSpendingsFactory: SpendingsFactory {
    public func create() async -> any ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions> {
        await SpendingsModel(
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            logger: logger
        )
    }
}
