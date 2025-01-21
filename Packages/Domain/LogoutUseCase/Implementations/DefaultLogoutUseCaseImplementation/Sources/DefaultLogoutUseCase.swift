import LogoutUseCase
import Entities
import AsyncExtensions
import Logging

public protocol LogoutPerformer: Sendable {
    @discardableResult
    func performLogout() async -> Bool
}

public actor DefaultLogoutUseCase {
    public let logger: Logger
    private let didLogoutBroadcast: AsyncSubject<LogoutReason>
    private let logoutPerformer: LogoutPerformer
    private let taskFactory: TaskFactory
    private var didLogoutSubscription: (any CancellableEventSource)?

    public init(
        shouldLogout: any AsyncBroadcast<Void>,
        taskFactory: TaskFactory,
        logoutPerformer: LogoutPerformer,
        logger: Logger
    ) async {
        self.didLogoutBroadcast = AsyncSubject(
            taskFactory: taskFactory,
            logger: logger
        )
        self.logoutPerformer = logoutPerformer
        self.taskFactory = taskFactory
        self.logger = logger
        didLogoutSubscription = await shouldLogout.subscribe { [weak self] reason in
            self?.taskFactory.task { [weak self] in
                guard let self else { return }
                guard await logoutPerformer.performLogout() else {
                    return
                }
                await self.didLogoutBroadcast.yield(.refreshTokenFailed)
            }
        }
    }
}

extension DefaultLogoutUseCase: LogoutUseCase {
    public var didLogoutPublisher: any AsyncBroadcast<LogoutReason> {
        didLogoutBroadcast
    }

    public func logout() async {
        await logoutPerformer.performLogout()
    }
}

extension DefaultLogoutUseCase: Loggable {}
