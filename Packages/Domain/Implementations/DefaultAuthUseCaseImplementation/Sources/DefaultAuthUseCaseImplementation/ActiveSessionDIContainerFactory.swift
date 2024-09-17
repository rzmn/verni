import Domain
import Api
import PersistentStorage
import AsyncExtensions
import DI

public protocol ActiveSessionDIContainerFactory: Sendable {
    func create(
        api: ApiProtocol,
        persistency: Persistency,
        longPoll: LongPoll,
        logoutSubject: AsyncSubject<LogoutReason>,
        userId: User.ID
    ) async -> ActiveSessionDIContainer
}
