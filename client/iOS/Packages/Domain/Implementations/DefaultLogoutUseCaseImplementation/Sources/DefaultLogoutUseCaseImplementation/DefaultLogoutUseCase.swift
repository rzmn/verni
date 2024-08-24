import Domain
import PersistentStorage
import Combine
internal import ApiDomainConvenience
internal import DataTransferObjects

public class DefaultLogoutUseCase {
    private let persistency: Persistency
    public let logoutIsRequired: AnyPublisher<LogoutReason, Never>

    public init(
        persistency: Persistency,
        logoutIsRequired: PassthroughSubject<LogoutReason, Never>
    ) {
        self.persistency = persistency
        self.logoutIsRequired = logoutIsRequired.eraseToAnyPublisher()
    }
}

extension DefaultLogoutUseCase: LogoutUseCase {
    public func logout() async {
        await persistency.invalidate()
    }
}
