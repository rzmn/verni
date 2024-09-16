import Domain
import PersistentStorage
import AsyncExtensions
import Base
import AsyncExtensions
internal import ApiDomainConvenience
internal import DataTransferObjects

public actor DefaultLogoutUseCase {
    private let didLogoutBroadcast: AsyncBroadcast<LogoutReason>
    private let persistency: Persistency
    private let taskFactory: TaskFactory
    private var didLogoutSubscription: (any CancellableEventSource)?
    private var loggedOutHandler = LoggedOutHandler()

    public init(
        persistency: Persistency,
        shouldLogout: any AsyncPublisher<LogoutReason>,
        taskFactory: TaskFactory
    ) async {
        self.didLogoutBroadcast = AsyncBroadcast(taskFactory: taskFactory)
        self.persistency = persistency
        self.taskFactory = taskFactory
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
    public var didLogoutPublisher: any AsyncPublisher<LogoutReason> {
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
            print("[debug] doLogout: skip")
            return false
        }
        print("[debug] doLogout: ok")
        taskFactory.task {
            await self.persistency.invalidate()
            print("[debug] doLogout: invalidated")
        }
        return true
    }
}
