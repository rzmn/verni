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
    private let didLogoutNotifier: EventPublisher<LogoutReason>
    private let logoutPerformer: LogoutPerformer
    private let taskFactory: TaskFactory

    public init(
        shouldLogout: EventPublisher<Void>,
        taskFactory: TaskFactory,
        logoutPerformer: LogoutPerformer,
        logger: Logger
    ) async {
        self.didLogoutNotifier = EventPublisher()
        self.logoutPerformer = logoutPerformer
        self.taskFactory = taskFactory
        self.logger = logger
        await shouldLogout.subscribeWeak(self) { [weak self] reason in
            guard let self else { return }
            taskFactory.task { [weak self] in
                guard let self else { return }
                guard await logoutPerformer.performLogout() else {
                    return
                }
                await didLogoutNotifier.notify(.refreshTokenFailed)
            }
        }
    }
}

extension DefaultLogoutUseCase: LogoutUseCase {
    public var didLogoutEventSource: any EventSource<LogoutReason> {
        didLogoutNotifier
    }

    public func logout() async {
        await logoutPerformer.performLogout()
    }
}

extension DefaultLogoutUseCase: Loggable {}
