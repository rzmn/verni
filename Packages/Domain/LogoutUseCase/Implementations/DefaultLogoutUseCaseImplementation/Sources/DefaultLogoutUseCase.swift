import LogoutUseCase
import Entities
import AsyncExtensions
import Logging

public actor DefaultLogoutUseCase {
    public let logger: Logger
    private let didLogoutBroadcast: AsyncSubject<LogoutReason>
    private let taskFactory: TaskFactory
    private var didLogoutSubscription: (any CancellableEventSource)?
    private var loggedOutHandler = LoggedOutHandler()

    public init(
        shouldLogout: any AsyncBroadcast<LogoutReason>,
        taskFactory: TaskFactory,
        logger: Logger
    ) async {
        self.didLogoutBroadcast = AsyncSubject(
            taskFactory: taskFactory,
            logger: logger
        )
        self.taskFactory = taskFactory
        self.logger = logger
        didLogoutSubscription = await shouldLogout.subscribe { [weak self] reason in
            self?.taskFactory.task { [weak self] in
                guard let self else { return }
                guard await self.doLogout() else {
                    return
                }
                await self.didLogoutBroadcast.yield(reason)
            }
        }
    }
}

extension DefaultLogoutUseCase: LogoutUseCase {
    public var didLogoutPublisher: any AsyncBroadcast<LogoutReason> {
        didLogoutBroadcast
    }

    public func logout() async {
        await doLogout()
    }
}

extension DefaultLogoutUseCase {
    @discardableResult
    private func doLogout() async -> Bool {
        guard await loggedOutHandler.allowLogout() else {
            return false
        }
        await self.session.logout()
        return true
    }
}

extension DefaultLogoutUseCase: Loggable {}
