import AppBase
import UserPreviewScreen
import UsersRepository
import SpendingsRepository
import Entities
import Logging

public final class DefaultUserPreviewFactory {
    private let usersRepository: UsersRepository
    private let spendingsRepository: SpendingsRepository
    private let usersRemoteDataSource: UsersRemoteDataSource
    private let hostId: User.Identifier
    private let user: User
    private let logger: Logger

    public init(
        user: User,
        hostId: User.Identifier,
        usersRepository: UsersRepository,
        spendingsRepository: SpendingsRepository,
        usersRemoteDataSource: UsersRemoteDataSource,
        logger: Logger
    ) {
        self.user = user
        self.hostId = hostId
        self.usersRepository = usersRepository
        self.spendingsRepository = spendingsRepository
        self.usersRemoteDataSource = usersRemoteDataSource
        self.logger = logger
    }
}

extension DefaultUserPreviewFactory: UserPreviewFactory {
    public func create() async -> any ScreenProvider<UserPreviewEvent, UserPreviewView, UserPreviewTransitions> {
        await UserPreviewModel(
            user: user,
            logger: logger,
            usersRepository: usersRepository,
            spendingsRepository: spendingsRepository,
            usersRemoteDataSource: usersRemoteDataSource,
            hostId: hostId
        )
    }
}
