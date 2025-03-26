import AppBase
import ActivitiesScreen
import OperationsRepository
import UsersRepository
import SpendingsRepository
import Logging

public final class DefaultActivitiesFactory {
    private let operationsRepository: OperationsRepository
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let logger: Logger

    public init(
        operationsRepository: OperationsRepository,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        logger: Logger
    ) {
        self.operationsRepository = operationsRepository
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
        self.logger = logger
    }
}

extension DefaultActivitiesFactory: ActivitiesFactory {
    public func create() async -> any ScreenProvider<ActivitiesEvent, ActivitiesView, ActivitiesTransitions> {
        await ActivitiesModel(
            operationsRepository: operationsRepository,
            usersRepository: usersRepository,
            spendingsRepository: spendingsRepository,
            logger: logger
        )
    }
}
