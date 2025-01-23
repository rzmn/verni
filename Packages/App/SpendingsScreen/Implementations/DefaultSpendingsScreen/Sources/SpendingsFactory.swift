import AppBase
import Logging
import SpendingsScreen
import SpendingsRepository
import UsersRepository

public final class DefaultSpendingsFactory {
    private let spendingsRepository: @Sendable () async -> SpendingsRepository
    private let usersRepository: @Sendable () async -> UsersRepository
    private let logger: Logger

    public init(
        spendingsRepository: @Sendable @escaping () async -> SpendingsRepository,
        usersRepository: @Sendable @escaping () async -> UsersRepository,
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
            spendingsRepository: await spendingsRepository(),
            usersRepository: await usersRepository(),
            logger: logger
        )
    }
}
