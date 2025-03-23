import AppBase
import Logging
import Entities
import SpendingsGroupScreen
import SpendingsRepository
import UsersRepository

public final class DefaultSpendingsGroupFactory {
    private let spendingsRepository: SpendingsRepository
    private let usersRepository: UsersRepository
    private let hostId: User.Identifier
    private let groupId: SpendingGroup.Identifier
    private let logger: Logger

    public init(
        spendingsRepository: SpendingsRepository,
        usersRepository: UsersRepository,
        hostId: User.Identifier,
        groupId: SpendingGroup.Identifier,
        logger: Logger
    ) {
        self.spendingsRepository = spendingsRepository
        self.usersRepository = usersRepository
        self.hostId = hostId
        self.groupId = groupId
        self.logger = logger
    }
}

extension DefaultSpendingsGroupFactory: SpendingsGroupFactory {
    public func create() async -> any ScreenProvider<SpendingsGroupEvent, SpendingsGroupView, SpendingsGroupTransitions> {
        await SpendingsGroupModel(
            spendingsRepository: spendingsRepository,
            usersRepository: usersRepository,
            hostId: hostId,
            groupId: groupId,
            logger: logger
        )
    }
}
