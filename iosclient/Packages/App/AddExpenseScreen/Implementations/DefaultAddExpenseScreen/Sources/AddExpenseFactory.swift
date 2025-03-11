import AppBase
import AddExpenseScreen
import ProfileRepository
import UsersRepository
import SpendingsRepository
import Logging

public final class DefaultAddExpenseFactory {
    private let profileRepository: ProfileRepository
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let logger: Logger

    public init(
        profileRepository: ProfileRepository,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        logger: Logger
    ) {
        self.profileRepository = profileRepository
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
        self.logger = logger
    }
}

extension DefaultAddExpenseFactory: AddExpenseFactory {
    public func create() async -> any ScreenProvider<AddExpenseEvent, AddExpenseView, AddExpenseTransitions> {
        await AddExpenseModel(
            profileRepository: profileRepository,
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            logger: logger
        )
    }
}
