import Domain
import Api
import PersistentStorage
import Combine
import DI

public protocol ActiveSessionDIContainerFactory: Sendable {
    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: PassthroughSubject<LogoutReason, Never>,
        userId: User.ID
    ) async -> ActiveSessionDIContainer
}
